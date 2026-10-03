class_name BuildInfo
extends RefCounted
## 빌드 정보. 웹 배포(.github/workflows/web-build.yml)가 내보내기 직전에 COMMIT을 실제 커밋 앞 7자리로 바꿔 쓴다.
## 타이틀 오른쪽 아래에 보여서, 오프라인 웹앱이 어느 버전을 들고 있는지 확인할 수 있다.

const COMMIT := "dev"
