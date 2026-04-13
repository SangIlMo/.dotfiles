---
name: pr-comments
description: PR 코멘트 확인, 수정사항 검토, 코드 수정 또는 답변 등록 후 resolve. Use when reviewing and addressing PR comments.
version: 1.0.0
user-invocable: true
argument: Optional PR number or URL. If omitted, uses the current branch's PR.
---

# PR Comments — PR 코멘트 확인 및 해결

PR의 리뷰 코멘트를 확인하고, 각 코멘트에 대해 코드 수정 또는 답변을 등록한 뒤 resolve합니다.

## Workflow

### 1. PR 식별

인자가 있으면 해당 PR 사용, 없으면 현재 브랜치의 PR 조회:
```bash
# 인자가 PR 번호 또는 URL이면 그대로 사용
# 없으면 현재 브랜치의 PR 조회
gh pr view --json number,url,title,headRefName
```
PR이 없으면 "현재 브랜치에 연결된 PR이 없습니다." 안내 후 중단.

### 2. 리뷰 코멘트 수집

**pending (unresolved) 코멘트만** 가져옵니다:
```bash
# PR 리뷰 코멘트 조회 (파일별 인라인 코멘트)
gh api repos/{owner}/{repo}/pulls/{number}/comments --jq '.[] | select(.position != null or .line != null)'

# PR 일반 리뷰 (CHANGES_REQUESTED, COMMENTED 등)
gh api repos/{owner}/{repo}/pulls/{number}/reviews
```

GraphQL로 resolved 상태 확인:
```bash
gh api graphql -f query='
  query($owner: String!, $repo: String!, $number: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $number) {
        reviewThreads(first: 100) {
          nodes {
            isResolved
            comments(first: 10) {
              nodes {
                body
                path
                line
                author { login }
                createdAt
              }
            }
          }
        }
      }
    }
  }
' -f owner='{owner}' -f repo='{repo}' -F number={number}
```

### 3. 코멘트 분류 및 요약

수집된 unresolved 코멘트를 사용자에게 요약 표시:

```
## PR #{number}: {title}

### Unresolved 코멘트 ({count}개)

1. **{file}:{line}** — @{author}
   > {comment body 요약}
   분류: 🔧 수정 필요 | 💬 답변 필요 | ❓ 질문

2. ...
```

각 코멘트를 다음으로 분류:
- **🔧 수정 필요**: 코드 변경을 요청하는 코멘트 (버그 지적, 리팩토링 제안, suggestion block 등)
- **💬 답변 필요**: 설명이나 의견을 요청하는 코멘트
- **❓ 질문**: 단순 질문

### 4. 사용자 확인

AskUserQuestion으로 진행 방식 확인:
- **전체 자동 처리**: 수정 가능한 것은 수정, 나머지는 답변 작성
- **하나씩 확인**: 각 코멘트마다 처리 방법 선택
- **취소**: 아무것도 하지 않음

### 5. 코멘트별 처리

각 unresolved 코멘트에 대해:

#### 🔧 수정 필요인 경우
1. 해당 파일의 관련 코드를 읽고 코멘트 내용 분석
2. GitHub suggestion block (```` ```suggestion ````)이 있으면 그대로 적용
3. 아니면 코멘트 의도에 맞게 코드 수정
4. 수정 후 답변 등록:
   ```bash
   gh api repos/{owner}/{repo}/pulls/{number}/comments/{comment_id}/replies \
     -f body="수정했습니다. {변경 내용 간략 설명}"
   ```
5. 해당 리뷰 thread resolve:
   ```bash
   gh api graphql -f query='
     mutation($threadId: ID!) {
       resolveReviewThread(input: {threadId: $threadId}) {
         thread { isResolved }
       }
     }
   ' -f threadId='{threadId}'
   ```

#### 💬 답변 필요 / ❓ 질문인 경우
1. 코드 컨텍스트를 파악하여 적절한 답변 작성
2. "하나씩 확인" 모드면 답변 내용을 사용자에게 보여주고 승인 요청
3. 승인되면 답변 등록:
   ```bash
   gh api repos/{owner}/{repo}/pulls/{number}/comments/{comment_id}/replies \
     -f body="{답변 내용}"
   ```
4. 사용자가 resolve 원하면 thread resolve

### 6. 수정사항 커밋 및 Push

코드 수정이 있었다면:
1. 변경된 파일을 확인하고 커밋:
   ```bash
   git add {modified files}
   git commit -m "fix: address PR review comments"
   git push
   ```
2. "하나씩 확인" 모드면 커밋 전 diff를 보여주고 확인

### 7. 완료 요약

```
## 처리 완료

- 🔧 수정: {n}개 코멘트 → 코드 수정 + resolve
- 💬 답변: {n}개 코멘트 → 답변 등록
- ⏭️ 건너뜀: {n}개
- 남은 unresolved: {n}개

커밋: {commit hash} (push 완료)
PR: {url}
```

## Important Notes

- resolve는 GraphQL API의 `resolveReviewThread` mutation 사용
- comment reply는 REST API `/comments/{id}/replies` 사용
- 코드 수정 시 최소한의 변경만 수행 (over-engineering 금지)
- suggestion block 적용 시 원본 그대로 적용
- 민감 파일 (.env 등) 수정 요청은 경고 후 사용자 확인
