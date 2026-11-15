// The narrow Linear write surface the scheduled agents are allowed to use.
//
// Reads still go through the read-only Linear MCP (`opencode.jsonc`), which is a
// real safety boundary: that endpoint exposes no mutations, so a prompt injection
// in a scanner message or a competitor's page cannot change Linear state. Pointing
// those agents at the read-write MCP endpoint instead would hand *every* Linear
// tool to three agents, including `review-coordinator`, which has no business
// writing anything.
//
// So writes go through this file instead. It exposes exactly five subcommands, two
// of which mutate:
//
//   states  --team GLOW                      list workflow states (read)
//   find    --team GLOW --fingerprint <fp>   dedup lookup (read)
//   labels  --team GLOW --names a,b          resolve label ids (read)
//   create  --team GLOW --title … --body-file … [--state "New"]   (WRITE)
//   move    --issue GLOW-181 --state "In Review"  change its state (WRITE)
//
// There is no delete, no project mutation, no comment, no assignee change. An agent
// that wanted to do something else to Linear has no tool for it.
//
// State names are matched tolerantly (`pickState`): exact, then spelling variants
// ("To Do"/"To-do" -> "Todo"), then partial, then Linear's state *type* as a last
// resort. `create --state` that matches nothing at all degrades to the team's
// default state (warned on stderr) rather than failing - a renamed state must not
// sink the ticket.
//
// Auth: LINEAR_API_KEY (read-write) for everything. Reads additionally accept
// LINEAR_READ_ONLY_API_KEY. A personal Linear API key is sent as a bare
// `Authorization: <key>` header - OAuth access tokens are the ones that take a
// `Bearer` prefix, and mixing them up returns 401.
//
// The pure helpers below are unit-tested in linear.test.ts; main() does the network
// IO and only runs when the file is executed directly.

import { readFileSync } from "node:fs";

export const LINEAR_API_URL = "https://api.linear.app/graphql";

/** Overridable so the IO layer can be exercised against a local stub. */
function apiUrl() {
  return process.env.LINEAR_API_URL || LINEAR_API_URL;
}

/** Linear's fixed priority scale: 0 none, 1 urgent, 2 high, 3 medium, 4 low. */
export const PRIORITY = { urgent: 1, high: 2, medium: 3, low: 4, none: 0 };

/**
 * Our finding severities onto Linear priorities. `high` deliberately maps to High
 * (2) and not Urgent (1): Urgent is reserved for a human, or for an explicit
 * `--priority 1` on something genuinely live like a committed credential.
 */
export const SEVERITY_PRIORITY = { high: 2, medium: 3, low: 4 };

/**
 * When a state name does not match literally, fall back to Linear's state `type`.
 * Several states share a type ("In Progress", "In Review" and "Ready to Merge" are
 * all `started`), so this is a last resort and the caller is warned when it fires.
 *
 * "new" maps to `backlog`: the GLOW intake state is called "New" and typed
 * `backlog` at position 0, so a renamed intake state still resolves to the
 * earliest backlog state.
 */
export const STATE_TYPE_FALLBACK = {
  "in progress": "started",
  "in review": "started",
  todo: "unstarted",
  new: "backlog",
  backlog: "backlog",
  done: "completed",
  canceled: "canceled",
  cancelled: "canceled",
};

export const QUERIES = {
  team: `query TeamByKey($key: String!) {
  teams(filter: { key: { eq: $key } }, first: 1) { nodes { id key name } }
}`,
  states: `query TeamStates($key: String!) {
  workflowStates(filter: { team: { key: { eq: $key } } }, first: 100) {
    nodes { id name type position }
  }
}`,
  labels: `query LabelsByName($names: [String!]) {
  issueLabels(filter: { name: { in: $names } }, first: 100) {
    nodes { id name team { key } }
  }
}`,
  // `description` is in the selection set on purpose: matchDuplicate confirms a
  // fuzzy search hit by looking for the exact Fingerprint line inside it, and
  // without it every dedup check would silently fall through to title matching.
  search: `query SearchIssues($term: String!, $teamId: String!) {
  searchIssues(term: $term, teamId: $teamId, first: 10, includeArchived: true) {
    nodes { id identifier title url description state { name type } }
  }
}`,
  create: `mutation CreateIssue($input: IssueCreateInput!) {
  issueCreate(input: $input) { success issue { id identifier url title } }
}`,
  move: `mutation MoveIssue($id: String!, $stateId: String!) {
  issueUpdate(id: $id, input: { stateId: $stateId }) {
    success issue { id identifier url state { id name type } }
  }
}`,
};

/** `--flag value` pairs plus bare `--flag` booleans. */
export function parseArgs(argv) {
  const out = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const token = argv[i];
    if (!token.startsWith("--")) {
      out._.push(token);
      continue;
    }
    const key = token.slice(2);
    const next = argv[i + 1];
    if (next === undefined || next.startsWith("--")) {
      out[key] = true;
    } else {
      out[key] = next;
      i++;
    }
  }
  return out;
}

/**
 * The dedup identity line. Written into every agent-filed Linear description and
 * matched by `find`, exactly like the `Fingerprint:` line the GitHub-issue path
 * already uses - so one finding has one identity whichever backlog it lands in.
 */
export function fingerprintLine(fingerprint) {
  return `Fingerprint: ${fingerprint}`;
}

export function hasFingerprint(text, fingerprint) {
  if (!fingerprint) return false;
  return (text ?? "").includes(fingerprintLine(fingerprint));
}

/**
 * Linear's full-text search is fuzzy, so a hit is only a duplicate once the exact
 * fingerprint line is present in the issue we matched. Callers that cannot read
 * descriptions fall back to an exact title match.
 */
export function matchDuplicate(issues, { fingerprint, title }) {
  for (const issue of issues ?? []) {
    if (fingerprint && hasFingerprint(issue.description, fingerprint)) return issue;
  }
  if (title) {
    const wanted = title.trim().toLowerCase();
    for (const issue of issues ?? []) {
      if ((issue.title ?? "").trim().toLowerCase() === wanted) return issue;
    }
  }
  return null;
}

/** Spelling-insensitive comparison key: "To Do" / "To-do" / "TODO" all become "todo". */
export function stateKey(name) {
  return String(name ?? "")
    .trim()
    .toLowerCase()
    .replace(/[\s_-]+/g, "");
}

/**
 * Resolve a human state name against a team's configured workflow states.
 * Returns `{ state, matchedBy }` so the caller can warn when only the loose
 * type fallback matched and the choice might not be what the operator meant.
 */
export function pickState(states, wanted) {
  const list = (states ?? []).filter((s) => s && typeof s.name === "string");
  const needle = (wanted ?? "").trim().toLowerCase();
  if (!needle) return { state: null, matchedBy: "none" };

  const exact = list.find((s) => s.name.toLowerCase() === needle);
  if (exact) return { state: exact, matchedBy: "name" };

  // "To-do" and "To Do" against a team whose state is literally "Todo": the
  // humans and the prompts keep spelling it differently, and a hyphen must
  // never be the reason a state fails to resolve.
  const key = stateKey(needle);
  const variant = list.find((s) => stateKey(s.name) === key);
  if (variant) return { state: variant, matchedBy: "name" };

  const partial = list.find((s) => s.name.toLowerCase().includes(needle));
  if (partial) return { state: partial, matchedBy: "partial" };

  const type =
    STATE_TYPE_FALLBACK[needle] ??
    Object.entries(STATE_TYPE_FALLBACK).find(([k]) => stateKey(k) === key)?.[1];
  if (type) {
    const byType = list
      .filter((s) => s.type === type)
      .sort((a, b) => (a.position ?? 0) - (b.position ?? 0));
    if (byType.length) return { state: byType[0], matchedBy: "type" };
  }
  return { state: null, matchedBy: "none" };
}

/** Build the `IssueCreateInput`, dropping anything the caller left unset. */
export function buildCreateInput({
  teamId,
  title,
  description,
  fingerprint,
  severity,
  priority,
  labelIds,
  stateId,
}) {
  if (!teamId) throw new Error("teamId is required");
  if (!title) throw new Error("title is required");

  let body = description ?? "";
  if (fingerprint && !hasFingerprint(body, fingerprint)) {
    body = `${body.trimEnd()}\n\n${fingerprintLine(fingerprint)}\n`;
  }

  const resolved =
    priority !== undefined && priority !== null && priority !== ""
      ? Number(priority)
      : SEVERITY_PRIORITY[severity];

  const input = { teamId, title };
  if (body.trim()) input.description = body;
  if (Number.isInteger(resolved) && resolved >= 0 && resolved <= 4) input.priority = resolved;
  if (labelIds?.length) input.labelIds = labelIds;
  if (stateId) input.stateId = stateId;
  return input;
}

/** Match requested label names to ids, preferring a team-scoped label over a global one. */
export function resolveLabelIds(labels, names, teamKey) {
  const wanted = (names ?? []).map((n) => n.trim().toLowerCase()).filter(Boolean);
  const ids = [];
  const missing = [];
  for (const name of wanted) {
    const candidates = (labels ?? []).filter((l) => (l.name ?? "").toLowerCase() === name);
    if (!candidates.length) {
      missing.push(name);
      continue;
    }
    const scoped = candidates.find((l) => l.team?.key === teamKey) ?? candidates[0];
    if (!ids.includes(scoped.id)) ids.push(scoped.id);
  }
  return { ids, missing };
}

/** Flatten a GraphQL response into a thrown Error or the data payload. */
export function unwrap(body) {
  if (body?.errors?.length) {
    throw new Error(body.errors.map((e) => e.message).join("; "));
  }
  if (!body?.data) throw new Error("Linear returned no data");
  return body.data;
}

// ---------------------------------------------------------------------------
// IO layer (not exercised by unit tests)
// ---------------------------------------------------------------------------

function apiKey({ write }) {
  const rw = process.env.LINEAR_API_KEY;
  if (rw) return rw;
  if (!write && process.env.LINEAR_READ_ONLY_API_KEY) {
    return process.env.LINEAR_READ_ONLY_API_KEY;
  }
  throw new Error(
    write
      ? "LINEAR_API_KEY (read-write) is not set - cannot write to Linear."
      : "Neither LINEAR_API_KEY nor LINEAR_READ_ONLY_API_KEY is set."
  );
}

async function gql(query, variables, { write = false } = {}) {
  const res = await fetch(apiUrl(), {
    method: "POST",
    headers: {
      // A personal API key goes in bare. `Bearer` is for OAuth access tokens.
      Authorization: apiKey({ write }),
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ query, variables }),
  });
  if (!res.ok) {
    throw new Error(`Linear API returned ${res.status}: ${await res.text()}`);
  }
  return unwrap(await res.json());
}

async function teamId(key) {
  const data = await gql(QUERIES.team, { key });
  const team = data.teams?.nodes?.[0];
  if (!team) throw new Error(`No Linear team with key "${key}"`);
  return team.id;
}

async function cmdStates(args) {
  const data = await gql(QUERIES.states, { key: args.team });
  console.log(JSON.stringify(data.workflowStates.nodes, null, 2));
}

async function cmdLabels(args) {
  const names = String(args.names ?? "")
    .split(",")
    .map((n) => n.trim())
    .filter(Boolean);
  const data = await gql(QUERIES.labels, { names });
  const { ids, missing } = resolveLabelIds(data.issueLabels.nodes, names, args.team);
  console.log(JSON.stringify({ ids, missing }, null, 2));
}

async function cmdFind(args) {
  const id = await teamId(args.team);
  const term = args.fingerprint || args.title;
  if (!term) throw new Error("find needs --fingerprint or --title");
  const data = await gql(QUERIES.search, { term: String(term), teamId: id });
  const nodes = data.searchIssues?.nodes ?? [];
  const duplicate = matchDuplicate(nodes, {
    fingerprint: args.fingerprint,
    title: args.title,
  });
  console.log(JSON.stringify({ duplicate, candidates: nodes }, null, 2));
}

async function cmdCreate(args) {
  const id = await teamId(args.team);

  let labelIds = [];
  if (args.labels) {
    const names = String(args.labels)
      .split(",")
      .map((n) => n.trim())
      .filter(Boolean);
    const data = await gql(QUERIES.labels, { names });
    const resolved = resolveLabelIds(data.issueLabels.nodes, names, args.team);
    labelIds = resolved.ids;
    // A missing label must not sink the ticket - the finding matters more than
    // its taxonomy, and Linear rejects the whole mutation on an unknown id.
    if (resolved.missing.length) {
      console.warn(
        `linear: no such label(s), creating without them: ${resolved.missing.join(", ")}`
      );
    }
  }

  let stateId;
  if (args.state) {
    const data = await gql(QUERIES.states, { key: args.team });
    const { state, matchedBy } = pickState(data.workflowStates.nodes, args.state);
    if (state) {
      if (matchedBy === "type") {
        console.warn(`linear: "${args.state}" matched only by type - using "${state.name}"`);
      }
      stateId = state.id;
    } else {
      // A renamed or removed state must not sink the ticket: create it in the
      // team's default state and say so, so the run can note it and the human
      // triaging the board sees where it landed.
      console.warn(
        `linear: no workflow state matching "${args.state}" on team ${args.team} - ` +
          "creating in the team's default state"
      );
    }
  }

  const description = args["body-file"]
    ? readFileSync(args["body-file"], "utf8")
    : (args.body ?? "");

  const input = buildCreateInput({
    teamId: id,
    title: args.title,
    description,
    fingerprint: args.fingerprint,
    severity: args.severity,
    priority: args.priority,
    labelIds,
    stateId,
  });

  const data = await gql(QUERIES.create, { input }, { write: true });
  if (!data.issueCreate?.success) throw new Error("Linear refused the issueCreate mutation");
  console.log(JSON.stringify(data.issueCreate.issue, null, 2));
}

async function cmdMove(args) {
  if (!args.issue) throw new Error("move needs --issue (e.g. GLOW-181)");
  const key = args.team || String(args.issue).split("-")[0];
  const data = await gql(QUERIES.states, { key });
  const { state, matchedBy } = pickState(data.workflowStates.nodes, args.state);
  if (!state) throw new Error(`No workflow state matching "${args.state}" on team ${key}`);
  if (matchedBy === "type") {
    console.warn(`linear: "${args.state}" matched only by type - using "${state.name}"`);
  }
  const moved = await gql(
    QUERIES.move,
    { id: String(args.issue), stateId: state.id },
    { write: true }
  );
  if (!moved.issueUpdate?.success) throw new Error("Linear refused the issueUpdate mutation");
  console.log(JSON.stringify(moved.issueUpdate.issue, null, 2));
}

const COMMANDS = {
  states: cmdStates,
  labels: cmdLabels,
  find: cmdFind,
  create: cmdCreate,
  move: cmdMove,
};

/** The only two subcommands that mutate Linear. */
export const WRITE_COMMANDS = ["create", "move"];

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const command = args._[0];
  const handler = COMMANDS[command];
  if (!handler) {
    console.error(`Usage: linear.mjs <${Object.keys(COMMANDS).join("|")}> [--flags]`);
    process.exit(2);
  }
  // Check the write credential up front. Both write commands resolve a team and
  // its states first, so without this they would burn three API calls and only
  // then report the real problem - and the agent reading the log would see a
  // confusing mid-sequence failure instead of "no write key".
  if (WRITE_COMMANDS.includes(command)) apiKey({ write: true });
  await handler(args);
}

const invokedDirectly = process.argv[1] && process.argv[1].endsWith("linear.mjs");
if (invokedDirectly) {
  main().catch((err) => {
    // Exit 1 with a readable reason: the agents are told to treat a non-zero exit
    // as "Linear is unavailable, fall back to a GitHub issue", never as fatal.
    console.error(`linear: ${err?.message ?? err}`);
    process.exit(1);
  });
}
