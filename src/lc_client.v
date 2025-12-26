import net.http
import json

/**
* Generates and returns header for leetcode.com api request.
*
* @param csrf_token
* @param leetcode_session
* @return request header
*/
fn leetcode_req_header(csrf_token string, leetcode_session string) !http.Header {

    header_template := {"cookie" : "LEETCODE_SESSION=${leetcode_session}; csrftoken=${csrf_token};",
                        "x-csrftoken" : "${csrf_token}",
                        "origin" : "https://leetcode.com",
                        "referer" : "https://leetcode.com/",
                        "Content-Type" : "application/json"
                        "User-Agent" : "Mozilla/5.0"}

    return http.new_custom_header_from_map(header_template)
}

struct SubmissionsDump {
    submissions_dump []Submission
    has_next bool
}

struct Submission {
    status_display string
    question_id int
    title_slug string
    title string
    lang string
    timestamp int
    runtime string
    memory string
    code string
}

/**
* Retrieves accepted leetcode submissions with metadata from Leetcode's API.
*
* @param page_offset
* @param page_limit
* @param header
* @return Response body
*/
fn get_leetcode_api_response(page_offset int, page_limit int, header http.Header) http.Response {

    // Request body
    request := http.Request {
        method: .get
        url: "https://leetcode.com/api/submissions/?offset=${page_offset}&limit=${page_limit}"
        header: header
    }

    // response := request.do() or {panic(err)}
    response := request.do() or { http.Response { status_code : 404} }

    return response
}

/**
* Performs repeated api requests to fetch all accepted submissions and parses repsonse bodies.
*
* @param header
* @return Parsed reponse bodies as list of string:string maps
*/
fn parse_leetcode_submissions(header http.Header) []Submission {

    mut poffset := 0
    plimit := 10
    mut has_next := true

    mut all_submissions := []Submission{}

    for has_next {
        response := get_leetcode_api_response(poffset, plimit, header)

        if response.status_code != 200 {
            continue
        }

        mut submissions := json.decode(SubmissionsDump, response.body) or {panic(err)}

        for sub in submissions.submissions_dump {
            if sub.status_display == "Accepted" {
                println("Completed ${sub.title_slug} @ ${sub.timestamp} in ${sub.lang}")
                all_submissions << sub
            }
        }

        poffset += plimit
        has_next = submissions.has_next
    }

    return all_submissions
}

struct Variable {
        title_slug string
    }

struct Query {
    operation_name string
    variables Variable
    query string
}

struct Response {
    data struct {
        question struct {
            content string
        }
    }
}

/**
* Fetches problem description for problem with title_slug <title_slug> and returns
* it as an html string
*
* @param token csrftoken
* @param session LEETCODE_SESSION
* @param title_slug title_slug
* @return html formatted string of the porblem description
*/
fn get_problem_readme(token string, session string, title_slug string) string {

    url := "https://leetcode.com/graphql"

    header_template := leetcode_req_header(token, session) or {panic(err)}

    query := Query {
        operation_name: "questionData"
        variables: Variable {
            title_slug: title_slug
        }
        query: "
        query questionData(\$title_slug: String!) {
          question(titleSlug: \$title_slug) {
            content
            title
            questionId
            difficulty
            likes
            dislikes
            exampleTestcases
          }
        }
        "
    }

    query_json := json.encode(query)

    req := http.Request {
        method: .post
        header: header_template
        data: query_json
        url: url
    }

    resp := req.do() or {panic(err)}
	resp_json := json.decode(Response, resp.body) or {panic(err)}
	doc := resp_json.data.question.content
    return doc
}

/**
* Streamlines submission fetching logic and reutruns a []Submission array with the parsed 'Accepted' submissions.
*
* @param token csrftoken
* @param session leetcode_session
* @return List of accepted leetcode submissions and their metadata
*/
fn get_accepted_submissions(token string, session string) []Submission {
    req_header := leetcode_req_header(token, session) or {panic(err)}
    println("Fetching & Parsing submissions...")
    return parse_leetcode_submissions(req_header)
}
