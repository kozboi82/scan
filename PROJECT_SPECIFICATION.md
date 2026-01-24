# 서정대학교 IT 자산관리 시스템 - 프로젝트 명세서

> **문서 버전**: 1.0  
> **작성일**: 2026-01-23  
> **작성자**: Park (전산실)  
> **목적**: Claude Code에서 개발 작업 시 참조용 전체 명세서

---

## 📋 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [기술 스택](#2-기술-스택)
3. [기능 요구사항](#3-기능-요구사항)
4. [데이터베이스 설계](#4-데이터베이스-설계)
5. [화면 설계](#5-화면-설계)
6. [API 설계](#6-api-설계)
7. [외부 연동](#7-외부-연동)
8. [개발 단계별 계획](#8-개발-단계별-계획)
9. [운영 가이드](#9-운영-가이드)

---

## 1. 프로젝트 개요

### 1.1 배경
- 서정대학교 전산실에서 교내 약 1,000대의 PC 및 IT 기자재 관리
- 현재 엑셀 기반 관리로 인한 문제점:
  - 연간 기자재 조사에 수개월 소요
  - 오차 발생 및 데이터 신뢰도 저하
  - 부서 이동/변경 추적 어려움
  - 수리 이력 파악 불가

### 1.2 목표
- **데이터 기반의 지능형 자산/보안 통합 관제 시스템** 구축
- 모바일 기반 실시간 자산 점검
- IP-사용자 매칭을 통한 자동 검증
- 수명주기/SW 버전 관리 자동화

### 1.3 핵심 가치
```
┌─────────────────────────────────────────────────────────────┐
│  기존 엑셀 방식        →        신규 시스템                  │
├─────────────────────────────────────────────────────────────┤
│  조사 기간: 3~6개월    →        실시간 (QR 스캔 즉시)        │
│  정확도: 70~80%        →        95% 이상                     │
│  이력 관리: 불가       →        전체 이력 추적               │
│  고장 분석: 수동       →        모델별 자동 통계             │
│  사용 여부: 수동 확인  →        V3/Ping 자동 체크            │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. 기술 스택

### 2.1 백엔드
| 구분 | 기술 | 버전 | 비고 |
|------|------|------|------|
| Framework | ASP.NET Web Forms | .NET Framework 4.8 | 기존 시스템과 통일 |
| Language | C# | 7.x | |
| Database | SQL Server | 2019 | Express 또는 Standard |
| ORM | ADO.NET + Stored Procedure | | 기존 패턴 유지 |

### 2.2 프론트엔드
| 구분 | 기술 | 비고 |
|------|------|------|
| UI Framework | Bootstrap 5 | 반응형 |
| JavaScript | jQuery 3.x | 기존 시스템과 통일 |
| Chart | Chart.js | 대시보드 |
| Tree | jsTree | 부서 트리 |
| Table | DataTables | 목록 그리드 |
| Excel | SheetJS (xlsx.js) | 엑셀 파싱 |

### 2.3 모바일 (PWA)
| 구분 | 기술 | 비고 |
|------|------|------|
| 방식 | Progressive Web App | 1차 구축 |
| 카메라 | HTML5 MediaDevices API | |
| OCR | Google Cloud Vision API | 또는 Tesseract + Regex |
| QR 스캔 | html5-qrcode | 무료 라이브러리 |
| 오프라인 | Service Worker | 선택적 |

### 2.4 서버 환경
```
┌─────────────────────────────────────────┐
│  Web Server: IIS 10                     │
│  OS: Windows Server 2019                │
│  SSL: 필수 (iOS 카메라 접근용)           │
│  내부망: 학교 네트워크                   │
└─────────────────────────────────────────┘
```

---

## 3. 기능 요구사항

### 3.1 기능 목록

#### 🔵 1단계 (필수/기본)
| ID | 기능명 | 설명 | 우선순위 |
|----|--------|------|----------|
| F01 | 부서별 보유현황 | 건물-층-부서-팀 트리 구조로 자산 조회 | ⭐⭐⭐ |
| F02 | 자산 등록/수정 | 시리얼, 모델, 위치, 사용자 등 기본 정보 | ⭐⭐⭐ |
| F03 | 엑셀 업로드 | 동적 열 매핑, 납품 데이터 등록 | ⭐⭐⭐ |
| F04 | 시리얼 조회 | 이동 이력, 수리 이력 통합 조회 | ⭐⭐⭐ |
| F05 | V3 데이터 연동 | CSV 업로드 → PC명/MAC 기준 매칭 | ⭐⭐⭐ |

#### 🟡 2단계 (핵심)
| ID | 기능명 | 설명 | 우선순위 |
|----|--------|------|----------|
| F06 | 모바일 점검 | PWA 앱으로 부서 점검, QR/OCR 스캔 | ⭐⭐⭐ |
| F07 | 수리/민원 관리 | 접수-진행-완료 워크플로우 | ⭐⭐ |
| F08 | 사용연한 모니터링 | 만료 임박 장비 알림 | ⭐⭐ |
| F09 | SW 버전 관리 | Win10 지원종료, 한글 버전 등 | ⭐⭐ |
| F10 | 모델별 고장 통계 | 제조사/모델별 민원 횟수 분석 | ⭐⭐ |

#### 🟢 3단계 (고급)
| ID | 기능명 | 설명 | 우선순위 |
|----|--------|------|----------|
| F11 | IP-사용자 매칭 | 학사시스템 로그인 로그 연동 | ⭐ |
| F12 | 사용자 IP 패턴 | 다중 IP 사용, 비정상 패턴 감지 | ⭐ |
| F13 | 자동 Ping 체크 | 스케줄러로 사용 여부 자동 확인 | ⭐ |
| F14 | 알림/대시보드 | 점검 포인트 자동 생성 | ⭐ |

### 3.2 상세 기능 명세

#### F01. 부서별 보유현황
```
[화면 구성]
┌─────────────────┬────────────────────────────────┐
│ 📂 부서 트리     │ 📋 자산 카드 리스트             │
│                 │                                │
│ 🏫 서정대학교    │  ┌────────┐ ┌────────┐        │
│ ├─ 🏢 본관      │  │ 💻 PC1  │ │ 💻 PC2  │        │
│ │  ├─ 교무실 ◀  │  │ S/N... │ │ S/N... │        │
│ │  └─ 행정실    │  └────────┘ └────────┘        │
│ └─ 📚 도서관    │                                │
└─────────────────┴────────────────────────────────┘

[상태 색상]
- 🟢 정상: 최근 점검 완료
- 🟡 점검필요: 3개월 이상 미점검
- 🔴 이상: 누락/분실/고장 의심
```

#### F03. 엑셀 업로드 (동적 열 매핑)
```
[프로세스]
1. 파일 업로드
2. 시스템이 첫 행(헤더) 읽음
3. 사용자에게 매핑 UI 제공
   ┌─────────────────────────────────────┐
   │ 엑셀 A열 "자산번호" → [시리얼번호 ▼] │
   │ 엑셀 B열 "PC이름"   → [PC명 ▼]      │
   │ 엑셀 C열 "부서"     → [부서 ▼]      │
   │ 엑셀 D열 "담당자"   → [사용자 ▼]    │
   └─────────────────────────────────────┘
4. 미리보기 확인
5. 검증 (중복 S/N, 필수값 누락)
6. 가등록 테이블에 임시 저장
7. 최종 확인 후 본 테이블 반영
```

#### F06. 모바일 점검 (핵심 시나리오)
```
[점검 프로세스]
1. 앱 접속 → 부서 선택 ("교무실")
2. [조사 시작] 버튼
3. QR 또는 S/N 스캔
4. 로직 분기:
   ┌─────────────────────────────────────────────────┐
   │ Case A: 정상                                    │
   │ → "교무실 소속 자산입니다. ✅ 점검 완료"         │
   ├─────────────────────────────────────────────────┤
   │ Case B: 위치 불일치                             │
   │ → "원래 '입학팀' 소속입니다.                    │
   │    교무실로 이동 처리하시겠습니까? [예/아니오]"  │
   ├─────────────────────────────────────────────────┤
   │ Case C: 미등록 자산                             │
   │ → "등록되지 않은 자산입니다.                    │
   │    [신규 등록] [임시 저장] [건너뛰기]"          │
   ├─────────────────────────────────────────────────┤
   │ Case D: 입고 대기 매칭                          │
   │ → "납품 대기 목록과 일치합니다.                 │
   │    입고 확인 처리하시겠습니까? [예]"            │
   └─────────────────────────────────────────────────┘
5. [조사 완료] → 결과 리포트
   - 총 점검: 13대
   - 정상: 12대
   - 누락: 1대 (LG-XY92AA)
```

#### F11. IP-사용자 매칭 (킬러 기능)
```
[데이터 흐름]
학사시스템 로그인 로그 → (일 배치) → TB_IP_ACCESS_LOG
                              ↓
                    자산 DB의 IP와 매칭
                              ↓
                    분석 결과 생성

[분석 케이스]
1. 사용자 불일치 감지
   - 자산대장: IP 10.10.1.5 → 사용자 "김철수"
   - 로그인 로그: 10.10.1.5 → 최근 90% "이영희"
   → [알림] "실사용자 변경 추정"

2. 유령 PC 감지
   - 자산대장에 등록된 10.10.1.10
   - 최근 3개월 로그인 기록 0건
   - Ping 응답 없음
   → [알림] "미사용 또는 폐기 누락"

3. 다중 IP 사용자
   - "홍길동"이 3개 이상 고정 IP에서 로그인
   → [알림] "다중 기기 사용 또는 IP 공유"
```

#### F13. 자동 Ping 체크
```
[스케줄]
- 매일 12:00 (점심)
- 매일 18:00 (퇴근 전)

[로직]
foreach (var asset in 모든_자산) {
    if (Ping(asset.IP_ADDRESS)) {
        asset.LAST_PING_DT = DateTime.Now;
        asset.STATUS = "NORMAL";
    } else {
        if (마지막_성공_후_30일_경과) {
            asset.STATUS = "CHECK_NEEDED";
            알림_생성("Ping 미응답 30일");
        }
    }
}
```

---

## 4. 데이터베이스 설계

### 4.1 ERD 개요
```
┌─────────────────────────────────────────────────────────────────┐
│                        기준정보 (마스터)                          │
├─────────────────────────────────────────────────────────────────┤
│  TB_DEPARTMENT      부서/위치 (계층: 건물→층→부서→팀)            │
│  TB_ASSET_TYPE      장비유형 (PC, 모니터, 프린터...)             │
│  TB_MANUFACTURER    제조사 (DELL, HP, 삼성...)                  │
│  TB_MODEL           모델정보 + 스펙 + 고장통계                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        자산 핵심                                 │
├─────────────────────────────────────────────────────────────────┤
│  TB_ASSET           자산마스터 (1대 = 1레코드)                   │
│    - 시리얼, 모델, 위치, 사용자                                  │
│    - IP, MAC, PC명                                              │
│    - OS/Office/한글 버전                                        │
│    - 구매일, 사용연한, 만료예정일(자동계산)                       │
│    - TPM 버전 (Win11 요건 체크용)                               │
└─────────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│    이력 관리     │ │   사용자 추적    │ │   외부 연동     │
├─────────────────┤ ├─────────────────┤ ├─────────────────┤
│ TB_ASSET_MOVE   │ │ TB_IP_ALLOCATION│ │ TB_V3_SYNC_DATA │
│ (이동이력)       │ │ (IP할당정보)     │ │ (안랩 데이터)   │
│                 │ │                 │ │                 │
│ TB_REPAIR_HIST  │ │ TB_IP_ACCESS_LOG│ │ TB_EXCEL_UPLOAD │
│ (수리/민원)      │ │ (접속로그)       │ │ (엑셀업로드)    │
│                 │ │                 │ │                 │
│ TB_CHECK_HIST   │ │ TB_USER_IP_STATS│ │                 │
│ (점검이력)       │ │ (IP사용통계)     │ │                 │
└─────────────────┘ └─────────────────┘ └─────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   알림/모니터링  │
                    ├─────────────────┤
                    │ TB_ALERT_CONFIG │
                    │ TB_ALERT_LOG    │
                    └─────────────────┘
```

### 4.2 핵심 테이블 상세

#### TB_ASSET (자산 마스터)
```sql
CREATE TABLE TB_ASSET (
    ASSET_ID        INT IDENTITY(1,1) PRIMARY KEY,
    ASSET_CD        VARCHAR(30) NOT NULL UNIQUE,    -- 자산관리번호 (QR코드용)
    SERIAL_NO       VARCHAR(50) NOT NULL,           -- 시리얼번호
    
    -- 장비 정보
    MODEL_ID        INT NOT NULL,
    TYPE_ID         INT NOT NULL,
    
    -- 현재 위치/사용자
    DEPT_ID         INT NULL,
    USER_NM         NVARCHAR(50) NULL,
    USER_ID         VARCHAR(20) NULL,
    
    -- 네트워크 정보
    IP_ADDRESS      VARCHAR(15) NULL,
    MAC_ADDRESS     VARCHAR(17) NULL,
    PC_NAME         VARCHAR(50) NULL,
    
    -- 소프트웨어 정보
    OS_VERSION      NVARCHAR(50) NULL,              -- Windows 11 Pro
    OFFICE_VERSION  NVARCHAR(50) NULL,
    HANGUL_VERSION  NVARCHAR(50) NULL,
    
    -- 하드웨어 스펙 (Win11 요건 체크용)
    ACTUAL_RAM_GB   INT NULL,
    ACTUAL_STORAGE  NVARCHAR(100) NULL,
    TPM_VERSION     DECIMAL(3,1) NULL,              -- TPM 2.0 등
    
    -- 수명주기
    PURCHASE_DATE   DATE NULL,
    LIFESPAN_MONTHS INT NULL,
    EXPIRE_DATE     AS DATEADD(MONTH, LIFESPAN_MONTHS, PURCHASE_DATE),
    WARRANTY_END    DATE NULL,
    
    -- 상태
    STATUS          VARCHAR(20) DEFAULT 'NORMAL',
    LAST_CHECK_DT   DATETIME NULL,
    LAST_V3_SYNC    DATETIME NULL,
    LAST_PING_DT    DATETIME NULL,
    
    -- 구매 정보
    PURCHASE_TYPE   VARCHAR(20) NULL,               -- CENTRAL, DEPT
    PURCHASE_PRICE  INT NULL,
    VENDOR_NM       NVARCHAR(50) NULL,
    
    -- 관리
    REMARK          NVARCHAR(500) NULL,
    USE_YN          CHAR(1) DEFAULT 'Y',
    CREATE_DT       DATETIME DEFAULT GETDATE(),
    UPDATE_DT       DATETIME DEFAULT GETDATE()
);
```

#### TB_DEPARTMENT (부서/위치 - 계층구조)
```sql
CREATE TABLE TB_DEPARTMENT (
    DEPT_ID         INT IDENTITY(1,1) PRIMARY KEY,
    DEPT_CD         VARCHAR(20) NOT NULL UNIQUE,
    DEPT_NM         NVARCHAR(100) NOT NULL,
    PARENT_DEPT_ID  INT NULL,                       -- 자기참조
    DEPT_LEVEL      TINYINT NOT NULL DEFAULT 1,     -- 1:건물, 2:층, 3:부서, 4:팀
    DEPT_TYPE       VARCHAR(20) NULL,
    SORT_ORDER      INT DEFAULT 0,
    USE_YN          CHAR(1) DEFAULT 'Y'
);
```

### 4.3 주요 뷰 (View)

#### 만료 임박 자산
```sql
CREATE VIEW VW_ASSET_EXPIRE_SOON AS
SELECT *
FROM VW_ASSET_FULL
WHERE DATEDIFF(DAY, GETDATE(), EXPIRE_DATE) BETWEEN 0 AND 90;
```

#### Win11 미지원 PC
```sql
CREATE VIEW VW_ASSET_WIN11_NOT_SUPPORTED AS
SELECT *
FROM VW_ASSET_FULL
WHERE OS_VERSION LIKE '%Windows 10%'
  AND (ACTUAL_RAM_GB < 4 OR TPM_VERSION < 2.0 OR TPM_VERSION IS NULL);
```

#### 모델별 고장 통계
```sql
CREATE VIEW VW_MODEL_ISSUE_STATS AS
SELECT 
    m.MODEL_ID,
    m.MODEL_NM,
    mf.MFR_NM,
    COUNT(DISTINCT a.ASSET_ID) AS TOTAL_COUNT,
    COUNT(r.REPAIR_ID) AS TOTAL_REPAIR_COUNT,
    SUM(CASE WHEN r.RECEIPT_DT >= DATEADD(MONTH, -6, GETDATE()) THEN 1 ELSE 0 END) AS RECENT_REPAIR_COUNT
FROM TB_MODEL m
LEFT JOIN TB_ASSET a ON m.MODEL_ID = a.MODEL_ID
LEFT JOIN TB_REPAIR_HIST r ON a.ASSET_ID = r.ASSET_ID
LEFT JOIN TB_MANUFACTURER mf ON m.MFR_ID = mf.MFR_ID
GROUP BY m.MODEL_ID, m.MODEL_NM, mf.MFR_NM;
```

### 4.4 전체 SQL 스크립트
> 📎 별첨: `db-schema-asset-management.sql`

---

## 5. 화면 설계

### 5.1 화면 목록

#### 관리자 웹 (PC)
| 화면ID | 화면명 | 설명 |
|--------|--------|------|
| W01 | 대시보드 | 요약 카드 + 차트 + 알림 |
| W02 | 자산 현황 | 트리 + 카드 리스트 |
| W03 | 자산 등록 | 신규/수정 폼 |
| W04 | 엑셀 업로드 | 동적 열 매핑 |
| W05 | 점검 이력 | 조사 결과 목록 |
| W06 | 수리/민원 | 접수-처리 관리 |
| W07 | 통계 | 모델별, 부서별 분석 |
| W08 | V3 연동 | CSV 업로드 + 매칭 결과 |
| W09 | 부서 관리 | 트리 구조 편집 |
| W10 | 설정 | 알림 조건, 사용연한 기본값 |

#### 모바일 PWA
| 화면ID | 화면명 | 설명 |
|--------|--------|------|
| M01 | 메인 | 부서 선택 + 빠른 검색 |
| M02 | 부서 점검 | 스캔 → 결과 → 처리 |
| M03 | 자산 상세 | 이력 조회 |
| M04 | 신규 등록 | 간편 등록 폼 |
| M05 | 수리 접수 | 민원 등록 |

### 5.2 UI 디자인 가이드
```
[기존 SJD 관리자 시스템 스타일 준수]

색상:
- 사이드바: #1e2a3a (네이비)
- 배경: #f5f7fa (라이트 그레이)
- 카드: #ffffff
- 강조: #4a90d9 (블루)

상태 색상:
- 정상: #28a745 (그린)
- 점검필요: #ffc107 (옐로우)
- 이상: #dc3545 (레드)
- 미등록: #6f42c1 (퍼플)

폰트:
- Pretendard (본문)
- Consolas (시리얼번호 등 코드)
```

### 5.3 UI 목업 파일
> 📎 별첨: `asset-management-sjd-style.html`

---

## 6. API 설계

### 6.1 RESTful API 목록

#### 자산 관리
| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | /api/asset | 자산 목록 조회 |
| GET | /api/asset/{id} | 자산 상세 조회 |
| GET | /api/asset/serial/{serialNo} | 시리얼로 조회 |
| POST | /api/asset | 자산 등록 |
| PUT | /api/asset/{id} | 자산 수정 |
| DELETE | /api/asset/{id} | 자산 삭제 (논리) |

#### 부서
| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | /api/department/tree | 트리 구조 조회 |
| GET | /api/department/{id}/assets | 부서별 자산 |

#### 점검
| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | /api/check/start | 점검 시작 |
| POST | /api/check/scan | 스캔 결과 처리 |
| POST | /api/check/complete | 점검 완료 |

#### 엑셀
| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | /api/excel/upload | 파일 업로드 |
| GET | /api/excel/{uploadId}/preview | 미리보기 |
| POST | /api/excel/{uploadId}/mapping | 매핑 저장 |
| POST | /api/excel/{uploadId}/confirm | 최종 반영 |

### 6.2 응답 형식
```json
{
  "success": true,
  "data": { ... },
  "message": "처리되었습니다.",
  "totalCount": 100
}
```

---

## 7. 외부 연동

### 7.1 V3 (안랩) 데이터 연동
```
[프로세스]
1. V3 관리 콘솔(APC)에서 CSV 내보내기
2. 시스템에 CSV 업로드
3. PC명 또는 MAC 주소로 자산 DB와 매칭
4. 매칭 결과:
   - MATCHED: 자산 정보 업데이트 (OS버전, 마지막 부팅 등)
   - UNMATCHED: 미등록 자산 → 알림 생성
   - CONFLICT: 정보 불일치 → 검토 필요

[매칭 우선순위]
1순위: MAC 주소 (가장 안정적)
2순위: PC명 (변경 가능성 있음)
3순위: IP 주소 (DHCP면 불안정)
```

### 7.2 학사시스템 로그 연동 (3단계)
```
[데이터 수집]
- 소스: 학사시스템 로그인 로그
- 항목: IP, 사용자ID, 로그인시간, 시스템구분
- 주기: 일 1회 배치 (새벽)

[필요 협조]
- 학사시스템 담당 부서
- 로그 테이블 접근 권한 또는 뷰 제공
```

### 7.3 Ping 자동 체크 (3단계)
```
[구현 방식]
- ASP.NET Background Service 또는 Windows Service
- 스케줄: 매일 12:00, 18:00

[로직]
foreach (asset in DB의_모든_자산) {
    bool alive = PingHost(asset.IP_ADDRESS, timeout: 1000ms);
    if (alive) {
        UpdateLastPingDate(asset.ASSET_ID);
    }
}
```

---

## 8. 개발 단계별 계획

### 8.1 1단계: 기초 데이터 구축 (4주)
```
[목표] 기존 엑셀 → DB 이전, 기본 조회 가능

Week 1-2:
□ DB 스키마 생성
□ 기준 데이터 입력 (부서, 장비유형, 제조사)
□ 기존 엑셀 분석 및 매핑 규칙 정의

Week 3-4:
□ 엑셀 업로드 기능 (동적 열 매핑)
□ 자산 기본 CRUD
□ 부서 트리 화면
□ 자산 카드 리스트 화면
```

### 8.2 2단계: 핵심 기능 (6주)
```
[목표] 모바일 점검 + 수리 이력 + V3 연동

Week 5-6:
□ V3 CSV 업로드 + 매칭 로직
□ 수리/민원 접수-처리 화면

Week 7-8:
□ 모바일 PWA 기본 구조
□ QR 스캔 기능
□ 부서 점검 프로세스

Week 9-10:
□ OCR 연동 (Google Vision 또는 대안)
□ 이동 처리 로직
□ 점검 결과 리포트
```

### 8.3 3단계: 고급 기능 (4주)
```
[목표] 자동화 + 분석 + 알림

Week 11-12:
□ 사용연한 만료 알림
□ SW 버전 관리 화면
□ 대시보드 차트

Week 13-14:
□ IP-사용자 매칭 (학사 로그 연동)
□ Ping 자동 체크 서비스
□ 알림 설정 및 알림 로그
```

### 8.4 마일스톤
```
┌─────────────────────────────────────────────────────────────┐
│ M1 (4주차): 엑셀 마이그레이션 완료, 기본 조회 가능          │
│ M2 (7주차): V3 연동 + 수리 이력 관리 가능                  │
│ M3 (10주차): 모바일 점검 운영 시작                         │
│ M4 (14주차): 전체 기능 완료, 안정화                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 9. 운영 가이드

### 9.1 데이터 권위 확보 정책 (중요!)
```
[권장 정책]
"자산관리 시스템에 등록되지 않은 장비는 기술지원 대상에서 제외"

[효과]
- 사용자들이 자발적으로 등록/신고
- 데이터 정확도 자연 상승
- 부서 담당자의 협조 유도
```

### 9.2 점검 주기
| 대상 | 주기 | 방법 |
|------|------|------|
| 전산실 구매 장비 | 분기 1회 | 전수 조사 (QR 스캔) |
| 부서 자체 구매 | 반기 1회 | 샘플링 또는 자진 신고 |
| V3 데이터 | 월 1회 | CSV 업로드 |
| Ping 체크 | 일 2회 | 자동 (스케줄러) |

### 9.3 QR 코드 운영
```
[도입 시점]
- 1단계 완료 후 (기존 데이터 DB화 이후)

[프로세스]
1. 자산 등록 시 ASSET_CD 자동 생성
2. QR 코드 라벨 출력 (시스템 내 기능)
3. 장비에 부착 (일정 위치 통일)
4. 이후 점검은 QR 스캔으로 진행

[효과]
- OCR 대비 인식률 100%
- 점검 속도 5~10배 향상
```

### 9.4 백업 정책
```
- DB 전체 백업: 일 1회 (새벽)
- 트랜잭션 로그: 1시간 단위
- 보관 기간: 30일
```

---

## 📎 별첨 파일 목록

| 파일명 | 설명 |
|--------|------|
| `db-schema-asset-management.sql` | DB 스키마 전체 (테이블, 뷰, 초기 데이터) |
| `asset-management-sjd-style.html` | UI 목업 (SJD 스타일) |

---

## 📞 문의

- **담당자**: Park (전산실)
- **내선**: 2507082

---

*이 문서는 Claude Code 개발 작업 시 참조용으로 작성되었습니다.*
