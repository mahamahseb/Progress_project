from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen


class GitHubClientError(RuntimeError):
    pass


class GitHubClient:
    def __init__(self, token: str | None = None) -> None:
        self._token = token

    def fetch_file(self, *, repo: str, branch: str, path: str) -> str:
        encoded_path = quote(path.strip("/"))
        encoded_branch = quote(branch, safe="")
        url = f"https://raw.githubusercontent.com/{repo}/{encoded_branch}/{encoded_path}"
        headers = {
            "Accept": "application/vnd.github.raw",
            "User-Agent": "project-progress-tracker",
        }
        if self._token:
            headers["Authorization"] = f"Bearer {self._token}"

        request = Request(url, headers=headers)

        try:
            with urlopen(request, timeout=15) as response:
                return response.read().decode("utf-8")
        except HTTPError as exc:
            raise GitHubClientError(f"GitHub returned {exc.code} for {repo}/{path}") from exc
        except URLError as exc:
            raise GitHubClientError(f"Could not reach GitHub: {exc.reason}") from exc
