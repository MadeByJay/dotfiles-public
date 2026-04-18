# Jira + Confluence shell functions
# Credentials sourced from secrets.zsh: JIRA_URL, JIRA_USER, JIRA_TOKEN, CONFLUENCE_URL

# ── Helpers ───────────────────────────────────────────────────────────────────

_jira_curl() {
    curl -s -u "$JIRA_USER:$JIRA_TOKEN" -H "Content-Type: application/json" "$@"
}

_confluence_curl() {
    curl -s -u "$JIRA_USER:$JIRA_TOKEN" -H "Content-Type: application/json" "$@"
}

_jira_check_creds() {
    if [[ -z "$JIRA_USER" || -z "$JIRA_TOKEN" || -z "$JIRA_URL" ]]; then
        echo "error: JIRA_USER, JIRA_TOKEN, JIRA_URL not set — source secrets.zsh" >&2
        return 1
    fi
}

# ── Jira ──────────────────────────────────────────────────────────────────────

# jira-get PD-1234
# Print ticket summary, status, assignee
jira-get() {
    _jira_check_creds || return 1
    local key="${1:?usage: jira-get PD-XXXX}"
    _jira_curl "$JIRA_URL/rest/api/3/issue/$key" \
        | python3 -c "
import json, sys
d = json.load(sys.stdin)
f = d['fields']
print(f\"[{d['key']}] {f['summary']}\")
print(f\"  Status:   {f['status']['name']}\")
print(f\"  Assignee: {(f.get('assignee') or {}).get('displayName', 'unassigned')}\")
print(f\"  Priority: {(f.get('priority') or {}).get('name', '-')}\")
desc = (f.get('description') or {})
texts = [c.get('text','') for b in desc.get('content',[]) for c in b.get('content',[])]
if texts:
    print(f\"  Desc:     {''.join(texts)[:200]}\")
"
}

# jira-create "Summary text" [task|bug|improvement]
# Create a ticket in the PD project
jira-create() {
    _jira_check_creds || return 1
    local summary="${1:?usage: jira-create \"Summary\" [task|bug|improvement]}"
    local type="${2:-task}"
    local type_map
    declare -A type_map=([task]=10001 [bug]=1 [improvement]=4 [feature]=2 [epic]=6 [subtask]=5)
    local type_id="${type_map[$type]:-10001}"
    _jira_curl -X POST "$JIRA_URL/rest/api/3/issue" -d "{
        \"fields\": {
            \"project\": { \"key\": \"PD\" },
            \"issuetype\": { \"id\": \"$type_id\" },
            \"summary\": \"$summary\"
        }
    }" | python3 -c "
import json, sys
d = json.load(sys.stdin)
if 'key' in d:
    print(f\"Created: {d['key']}  {d['self']}\")
else:
    print(json.dumps(d, indent=2))
"
}

# jira-link PD-1234 PD-5678 [relates|blocks|clones]
# Link two tickets
jira-link() {
    _jira_check_creds || return 1
    local from="${1:?usage: jira-link PD-XXXX PD-YYYY [relates|blocks|clones]}"
    local to="${2:?usage: jira-link PD-XXXX PD-YYYY [relates|blocks|clones]}"
    local type="${3:-Relates}"
    _jira_curl -X POST "$JIRA_URL/rest/api/3/issueLink" -d "{
        \"type\": { \"name\": \"$type\" },
        \"inwardIssue\": { \"key\": \"$from\" },
        \"outwardIssue\": { \"key\": \"$to\" }
    }" && echo "Linked $from → $to ($type)"
}

# jira-mine
# List open tickets assigned to you
jira-mine() {
    _jira_check_creds || return 1
    _jira_curl "$JIRA_URL/rest/api/3/search?jql=assignee=currentUser()+AND+resolution=Unresolved+ORDER+BY+updated+DESC&maxResults=20" \
        | python3 -c "
import json, sys
d = json.load(sys.stdin)
for i in d.get('issues', []):
    f = i['fields']
    print(f\"{i['key']:<12} [{f['status']['name']:<16}] {f['summary']}\")
"
}

# jira-open PD-1234
# Open ticket in browser
jira-open() {
    local key="${1:?usage: jira-open PD-XXXX}"
    xdg-open "$JIRA_URL/browse/$key" 2>/dev/null || open "$JIRA_URL/browse/$key"
}

# ── Confluence ────────────────────────────────────────────────────────────────

# confluence-search "query" [SPACE_KEY]
# Search pages by keyword, optional space filter
confluence-search() {
    _jira_check_creds || return 1
    local query="${1:?usage: confluence-search \"query\" [SPACE_KEY]}"
    local space="$2"
    local cql="text~\"$query\""
    [[ -n "$space" ]] && cql="$cql AND space=$space"
    _confluence_curl "$CONFLUENCE_URL/rest/api/content/search?cql=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$cql")&limit=10" \
        | python3 -c "
import json, sys
d = json.load(sys.stdin)
for p in d.get('results', []):
    space = p.get('_expandable', {}).get('space', '').split('/')[-1]
    print(f\"{p['id']:<12} [{p.get('space',{}).get('key','?'):>5}]  {p['title']}\")
"
}

# confluence-get PAGE_ID
# Print page title + plain-text body excerpt
confluence-get() {
    _jira_check_creds || return 1
    local page_id="${1:?usage: confluence-get PAGE_ID}"
    _confluence_curl "$CONFLUENCE_URL/rest/api/content/$page_id?expand=body.storage,version,space" \
        | python3 -c "
import json, sys, re
d = json.load(sys.stdin)
print(f\"Title:   {d['title']}\")
print(f\"Space:   {d['space']['key']}\")
print(f\"Version: {d['version']['number']}\")
body = d['body']['storage']['value']
text = re.sub(r'<[^>]+>', '', body)[:500]
print(f\"\n{text.strip()}\")
"
}

# confluence-list [SPACE_KEY]
# List pages in a space (default: DVV)
confluence-list() {
    _jira_check_creds || return 1
    local space="${1:-DVV}"
    _confluence_curl "$CONFLUENCE_URL/rest/api/content?spaceKey=$space&type=page&limit=50&expand=title" \
        | python3 -c "
import json, sys
d = json.load(sys.stdin)
for p in d.get('results', []):
    print(f\"{p['id']:<12}  {p['title']}\")
"
}

# confluence-link-jira PAGE_ID PD-1234 "Link title"
# Add a remote link from a Jira ticket to a Confluence page
confluence-link-jira() {
    _jira_check_creds || return 1
    local page_id="${1:?usage: confluence-link-jira PAGE_ID PD-XXXX \"Title\"}"
    local jira_key="${2:?usage: confluence-link-jira PAGE_ID PD-XXXX \"Title\"}"
    local title="${3:-Confluence page}"
    local page_url="$CONFLUENCE_URL/pages/$page_id"
    _jira_curl -X POST "$JIRA_URL/rest/api/3/issue/$jira_key/remotelink" -d "{
        \"object\": { \"url\": \"$page_url\", \"title\": \"$title\" }
    }" && echo "Linked $page_id → $jira_key"
}
