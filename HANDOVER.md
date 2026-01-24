# OCR 시리얼 인식 프로젝트 인수인계 문서

## 프로젝트 개요

IT 자산의 시리얼 번호(S/N)를 OCR로 인식하는 테스트 페이지 모음.
다양한 OCR 방식(Google Vision, Azure Vision, LLM, QR/Barcode)을 비교 테스트할 수 있음.

## GitHub 배포 정보

- **Repository**: https://github.com/kozboi82/scan
- **GitHub Pages**: https://kozboi82.github.io/scan/
- **Branch**: main

## 파일 구조

```
E:\Project\시리얼인식\
├── index.html              # 메인 네비게이션 페이지
├── ocr-test-google.html    # Google Vision API OCR (v1.2)
├── ocr-test-azure.html     # Azure Vision API OCR (v1.2)
├── ocr-test-llm.html       # LLM Vision OCR - Claude/GPT (v1.2)
├── ocr-test-qrcode.html    # QR/Barcode 스캐너
├── .gitignore              # Git 제외 파일 목록
└── HANDOVER.md             # 이 문서
```

### Git에서 제외된 파일 (.gitignore)
```
asset-management-design-spec.md
asset-management-sjd-style.html
db-schema-asset-management.sql
PROJECT_SPECIFICATION.md
.claude/
```

## 각 페이지 기능

### 1. Google Vision API (`ocr-test-google.html`) - v1.2
- **API**: Google Cloud Vision API
- **기능**: 이미지에서 텍스트 추출 후 시리얼 번호 패턴 분석
- **설정 필요**: Google Cloud API Key
- **특징**:
  - 이미지 자동 리사이즈 (1280px, JPEG 80%)
  - extractSerial v2.0 적용 (샘플 기반 패턴)
  - LocalStorage에 API Key 저장

### 2. Azure Vision API (`ocr-test-azure.html`) - v1.2
- **API**: Azure Computer Vision Read API v3.2
- **기능**: Google과 동일 (OCR → 시리얼 추출)
- **설정 필요**: Azure Endpoint + API Key
- **특징**:
  - 비동기 처리 (submit → polling → result)
  - extractSerial v2.0 적용
  - Google과 속도 비슷함

### 3. LLM Vision (`ocr-test-llm.html`) - v1.2
- **API**: Claude API (Anthropic) / OpenAI API
- **기능**: LLM으로 이미지 분석하여 시리얼 추출
- **설정 필요**: Claude API Key 또는 OpenAI API Key
- **특징**:
  - 모델 선택 가능: Fast (Haiku/4o-mini) / Smart (Sonnet/4o)
  - QR/Barcode/S/N 동시 분석 프롬프트
  - JSON 형식 응답 (qr_text, barcode_text, sn_text, final_serial)
  - **주의**: Fast 모델은 인식률 낮음, GPT-4o는 ~7초 소요

### 4. QR/Barcode Scanner (`ocr-test-qrcode.html`)
- **라이브러리**: html5-qrcode
- **기능**: QR코드 및 바코드 스캔
- **지원 포맷**: QR, Code128, Code39, EAN, UPC 등
- **특징**:
  - 카메라 모드: 실시간 스캔 (권장, 인식률 높음)
  - 파일 업로드 모드: 이미지 파일 스캔
  - HEIC → JPEG 변환 지원 (아이폰 사진)
  - **주의**: 파일 업로드보다 카메라 모드가 훨씬 인식률 높음

## 시리얼 번호 추출 함수 (extractSerial v2.0)

### 적용된 페이지
- ocr-test-google.html
- ocr-test-azure.html

### 주요 패턴 (1500+ 샘플 기반)

| 패턴 유형 | 예시 | 정규식 |
|----------|------|--------|
| LG 시리얼 | 40LGD5K202209000098 | `\d{2,3}LG[A-Z]\d[A-Z][A-Z0-9]{10,}` |
| 날짜 기반 | 220920002-0001 | `\d{6}\d{3}-\d{4}` |
| G1L/G2L | G1L701E19013-00002 | `G[12]L\d{3}E\d{5}-\d{5}` |
| TAG | TAG-N10MBA0309-L00009 | `TAG-?N\d+[A-Z]+\d+-[A-Z]?\d+` |
| CW | CWCUH4ZM801223R | `CW[A-Z0-9]{2,4}H[0-9][A-Z]{2}[A-Z0-9]{6,}` |
| BZ | BZUNH4TNA04140 | `BZ[A-Z0-9]{2,4}H[0-9][A-Z]{2}[A-Z0-9]{5,}` |
| K-prefix | KHTX98CN2A000RY | `K[A-Z]{2,3}\d{2}[A-Z0-9]{2,}[A-Z0-9]{5,}` |
| LED | LED2215020116J1 | `LED\d{10}[A-Z]\d` |
| ZZ | ZZMUH4ZM107706J | `ZZ[A-Z0-9]{2,4}H[0-9][A-Z]{2}[A-Z0-9]{5,}` |

### 제외 단어 (excludeWords)
```
number, serial, model, part, product, type, version, no, sn, id, null, test, match, barcode, qr, code
```

## 알려진 이슈 및 제한사항

### 1. 로컬 테스트 불가 (Google API)
- `file://` 프로토콜에서 Google API 호출 시 "Requests from referer null are blocked" 에러
- **해결**: 로컬 서버 사용 (`python -m http.server`) 또는 GitHub Pages 이용

### 2. LLM Fast 모델 인식률
- GPT-4o-mini, Claude Haiku는 시리얼 인식 정확도 낮음
- GPT-4o는 정확하지만 ~7초 소요로 실용성 낮음

### 3. QR/Barcode 파일 업로드
- html5-qrcode의 `scanFile` 기능은 카메라 모드보다 인식률 낮음
- 카메라 실시간 스캔 권장

### 4. 아이폰 HEIC 포맷
- QR 페이지에서 HEIC → JPEG 변환 추가됨
- OCR 페이지들은 canvas 리사이즈 과정에서 자동 변환됨

## API 키 설정 방법

### Google Cloud Vision
1. Google Cloud Console → API & Services → Credentials
2. API Key 생성
3. Cloud Vision API 활성화
4. 페이지에서 API Key 입력 (LocalStorage에 저장됨)

### Azure Computer Vision
1. Azure Portal → Computer Vision 리소스 생성
2. Keys and Endpoint에서 키/엔드포인트 복사
3. 페이지에서 입력

### Claude API (Anthropic)
1. console.anthropic.com에서 API Key 발급
2. 페이지에서 입력

### OpenAI API
1. platform.openai.com에서 API Key 발급
2. 페이지에서 입력

## 삭제된 파일들

이전 세션에서 삭제된 파일:
- `ocr-test-hybrid.html` - QR+OCR 하이브리드 (인식 안됨)
- `ocr-test-tesseract.html` - Tesseract.js (불필요)
- `sn-scanner-test.html` - 테스트용 파일

## Git 명령어 참고

```bash
# 현재 상태 확인
git status

# 변경사항 커밋 & 푸시
git add .
git commit -m "메시지"
git push

# 원격 저장소 확인
git remote -v
```

## 향후 개선 가능 사항

1. **시리얼 패턴 추가**: 새로운 장비 유형 발견 시 패턴 추가
2. **배치 처리**: 여러 이미지 연속 처리 기능
3. **결과 내보내기**: CSV/Excel 다운로드 기능
4. **히스토리**: 이전 스캔 결과 저장/조회

---

*마지막 업데이트: 2026-01-24*
*작성: Claude Opus 4.5*
