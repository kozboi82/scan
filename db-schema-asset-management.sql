-- ============================================================
-- 서정대학교 IT 자산관리 시스템 DB 스키마
-- 작성일: 2026-01-23
-- 대상 DB: SQL Server
-- ============================================================

-- ============================================================
-- 1. 기준정보 테이블 (마스터)
-- ============================================================

-- 1-1. 부서/위치 (계층구조)
CREATE TABLE TB_DEPARTMENT (
    DEPT_ID         INT IDENTITY(1,1) PRIMARY KEY,
    DEPT_CD         VARCHAR(20) NOT NULL UNIQUE,        -- 부서코드 (예: BLD01-F02-D003)
    DEPT_NM         NVARCHAR(100) NOT NULL,             -- 부서명
    PARENT_DEPT_ID  INT NULL,                           -- 상위부서 ID (자기참조)
    DEPT_LEVEL      TINYINT NOT NULL DEFAULT 1,         -- 1:건물, 2:층, 3:부서, 4:팀
    DEPT_TYPE       VARCHAR(20) NULL,                   -- BUILDING, FLOOR, DEPARTMENT, TEAM
    SORT_ORDER      INT DEFAULT 0,                      -- 정렬순서
    USE_YN          CHAR(1) DEFAULT 'Y',
    CREATE_DT       DATETIME DEFAULT GETDATE(),
    UPDATE_DT       DATETIME DEFAULT GETDATE(),
    
    CONSTRAINT FK_DEPT_PARENT FOREIGN KEY (PARENT_DEPT_ID) 
        REFERENCES TB_DEPARTMENT(DEPT_ID)
);

-- 인덱스
CREATE INDEX IX_DEPT_PARENT ON TB_DEPARTMENT(PARENT_DEPT_ID);
CREATE INDEX IX_DEPT_LEVEL ON TB_DEPARTMENT(DEPT_LEVEL);

-- 1-2. 장비 유형
CREATE TABLE TB_ASSET_TYPE (
    TYPE_ID         INT IDENTITY(1,1) PRIMARY KEY,
    TYPE_CD         VARCHAR(20) NOT NULL UNIQUE,        -- PC, MONITOR, PRINTER, NOTEBOOK, ETC
    TYPE_NM         NVARCHAR(50) NOT NULL,
    TYPE_CATEGORY   VARCHAR(20) NULL,                   -- HW, SW, NETWORK
    DEFAULT_LIFESPAN_MONTHS INT NULL,                   -- 기본 사용연한 (개월)
    USE_YN          CHAR(1) DEFAULT 'Y',
    SORT_ORDER      INT DEFAULT 0
);

-- 1-3. 제조사
CREATE TABLE TB_MANUFACTURER (
    MFR_ID          INT IDENTITY(1,1) PRIMARY KEY,
    MFR_CD          VARCHAR(20) NOT NULL UNIQUE,
    MFR_NM          NVARCHAR(50) NOT NULL,              -- DELL, HP, 삼성, LG 등
    USE_YN          CHAR(1) DEFAULT 'Y'
);

-- 1-4. 모델 정보
CREATE TABLE TB_MODEL (
    MODEL_ID        INT IDENTITY(1,1) PRIMARY KEY,
    MODEL_CD        VARCHAR(50) NOT NULL UNIQUE,        -- 모델코드
    MODEL_NM        NVARCHAR(100) NOT NULL,             -- 모델명 (OptiPlex 7090)
    MFR_ID          INT NOT NULL,                       -- 제조사
    TYPE_ID         INT NOT NULL,                       -- 장비유형
    
    -- 스펙 정보 (PC용)
    SPEC_CPU        NVARCHAR(100) NULL,
    SPEC_RAM_GB     INT NULL,                           -- 램 용량 (GB)
    SPEC_STORAGE    NVARCHAR(100) NULL,                 -- 저장장치
    SPEC_OS_SUPPORT NVARCHAR(100) NULL,                 -- 지원 OS (Win10, Win11)
    
    -- 스펙 정보 (모니터용)
    SPEC_INCH       DECIMAL(4,1) NULL,                  -- 인치
    SPEC_RESOLUTION NVARCHAR(20) NULL,                  -- 해상도
    
    -- 통계용
    TOTAL_COUNT     INT DEFAULT 0,                      -- 총 등록 수
    ISSUE_COUNT     INT DEFAULT 0,                      -- 총 민원/고장 수
    
    USE_YN          CHAR(1) DEFAULT 'Y',
    CREATE_DT       DATETIME DEFAULT GETDATE(),
    
    CONSTRAINT FK_MODEL_MFR FOREIGN KEY (MFR_ID) REFERENCES TB_MANUFACTURER(MFR_ID),
    CONSTRAINT FK_MODEL_TYPE FOREIGN KEY (TYPE_ID) REFERENCES TB_ASSET_TYPE(TYPE_ID)
);

CREATE INDEX IX_MODEL_MFR ON TB_MODEL(MFR_ID);
CREATE INDEX IX_MODEL_TYPE ON TB_MODEL(TYPE_ID);


-- ============================================================
-- 2. 자산 핵심 테이블
-- ============================================================

-- 2-1. 자산 마스터 (장비 1대 = 1레코드)
CREATE TABLE TB_ASSET (
    ASSET_ID        INT IDENTITY(1,1) PRIMARY KEY,
    ASSET_CD        VARCHAR(30) NOT NULL UNIQUE,        -- 자산관리번호 (QR코드용)
    SERIAL_NO       VARCHAR(50) NOT NULL,               -- 시리얼번호 (제조사 부여)
    
    -- 장비 정보
    MODEL_ID        INT NOT NULL,
    TYPE_ID         INT NOT NULL,
    
    -- 현재 위치/사용자
    DEPT_ID         INT NULL,                           -- 현재 부서
    USER_NM         NVARCHAR(50) NULL,                  -- 현재 사용자
    USER_ID         VARCHAR(20) NULL,                   -- 사용자 ID (학번/사번)
    
    -- 네트워크 정보
    IP_ADDRESS      VARCHAR(15) NULL,
    MAC_ADDRESS     VARCHAR(17) NULL,                   -- 00:1A:2B:3C:4D:5E
    PC_NAME         VARCHAR(50) NULL,                   -- 컴퓨터 이름
    
    -- 소프트웨어 정보 (V3 연동 등에서 업데이트)
    OS_VERSION      NVARCHAR(50) NULL,                  -- Windows 11 Pro
    OFFICE_VERSION  NVARCHAR(50) NULL,                  -- Microsoft 365
    HANGUL_VERSION  NVARCHAR(50) NULL,                  -- 한컴오피스 2020
    
    -- 하드웨어 스펙 (실제 확인값)
    ACTUAL_RAM_GB   INT NULL,
    ACTUAL_STORAGE  NVARCHAR(100) NULL,
    
    -- 수명주기
    PURCHASE_DATE   DATE NULL,                          -- 구매일
    LIFESPAN_MONTHS INT NULL,                           -- 사용연한 (개월)
    EXPIRE_DATE     AS DATEADD(MONTH, LIFESPAN_MONTHS, PURCHASE_DATE), -- 만료예정일 (계산열)
    WARRANTY_END    DATE NULL,                          -- 보증기간 종료일
    
    -- 상태
    STATUS          VARCHAR(20) DEFAULT 'NORMAL',       -- NORMAL, CHECK_NEEDED, ISSUE, DISPOSED, LOST
    LAST_CHECK_DT   DATETIME NULL,                      -- 마지막 점검일
    LAST_V3_SYNC    DATETIME NULL,                      -- V3 마지막 동기화
    LAST_PING_DT    DATETIME NULL,                      -- 마지막 Ping 성공
    
    -- 구매 정보
    PURCHASE_TYPE   VARCHAR(20) NULL,                   -- CENTRAL(전산실구매), DEPT(부서구매)
    PURCHASE_PRICE  INT NULL,
    VENDOR_NM       NVARCHAR(50) NULL,                  -- 납품업체
    
    -- 관리
    REMARK          NVARCHAR(500) NULL,
    USE_YN          CHAR(1) DEFAULT 'Y',
    CREATE_DT       DATETIME DEFAULT GETDATE(),
    CREATE_USER     VARCHAR(20) NULL,
    UPDATE_DT       DATETIME DEFAULT GETDATE(),
    UPDATE_USER     VARCHAR(20) NULL,
    
    CONSTRAINT FK_ASSET_MODEL FOREIGN KEY (MODEL_ID) REFERENCES TB_MODEL(MODEL_ID),
    CONSTRAINT FK_ASSET_TYPE FOREIGN KEY (TYPE_ID) REFERENCES TB_ASSET_TYPE(TYPE_ID),
    CONSTRAINT FK_ASSET_DEPT FOREIGN KEY (DEPT_ID) REFERENCES TB_DEPARTMENT(DEPT_ID)
);

-- 인덱스 (조회 패턴 기반)
CREATE UNIQUE INDEX IX_ASSET_SERIAL ON TB_ASSET(SERIAL_NO);
CREATE INDEX IX_ASSET_DEPT ON TB_ASSET(DEPT_ID);
CREATE INDEX IX_ASSET_MODEL ON TB_ASSET(MODEL_ID);
CREATE INDEX IX_ASSET_IP ON TB_ASSET(IP_ADDRESS);
CREATE INDEX IX_ASSET_MAC ON TB_ASSET(MAC_ADDRESS);
CREATE INDEX IX_ASSET_PCNAME ON TB_ASSET(PC_NAME);
CREATE INDEX IX_ASSET_STATUS ON TB_ASSET(STATUS);
CREATE INDEX IX_ASSET_EXPIRE ON TB_ASSET(EXPIRE_DATE);


-- ============================================================
-- 3. 이력 테이블
-- ============================================================

-- 3-1. 자산 이동 이력
CREATE TABLE TB_ASSET_MOVE_HIST (
    HIST_ID         INT IDENTITY(1,1) PRIMARY KEY,
    ASSET_ID        INT NOT NULL,
    
    -- 이동 정보
    MOVE_TYPE       VARCHAR(20) NOT NULL,               -- RECEIVE(입고), MOVE(이동), DISPOSE(폐기), REPAIR_IN(수리입고), REPAIR_OUT(수리출고)
    
    FROM_DEPT_ID    INT NULL,                           -- 이전 부서
    TO_DEPT_ID      INT NULL,                           -- 이후 부서
    FROM_USER_ID    VARCHAR(20) NULL,
    TO_USER_ID      VARCHAR(20) NULL,
    
    MOVE_DT         DATETIME DEFAULT GETDATE(),
    MOVE_REASON     NVARCHAR(200) NULL,
    REMARK          NVARCHAR(500) NULL,
    
    CREATE_USER     VARCHAR(20) NULL,
    CREATE_DT       DATETIME DEFAULT GETDATE(),
    
    CONSTRAINT FK_MOVEHIST_ASSET FOREIGN KEY (ASSET_ID) REFERENCES TB_ASSET(ASSET_ID)
);

CREATE INDEX IX_MOVEHIST_ASSET ON TB_ASSET_MOVE_HIST(ASSET_ID);
CREATE INDEX IX_MOVEHIST_DT ON TB_ASSET_MOVE_HIST(MOVE_DT);

-- 3-2. 수리/민원 이력
CREATE TABLE TB_REPAIR_HIST (
    REPAIR_ID       INT IDENTITY(1,1) PRIMARY KEY,
    ASSET_ID        INT NOT NULL,
    
    REPAIR_TYPE     VARCHAR(20) NOT NULL,               -- REPAIR(수리), COMPLAINT(민원), REPLACE(교체)
    REPAIR_STATUS   VARCHAR(20) DEFAULT 'RECEIVED',     -- RECEIVED(접수), PROGRESS(진행), COMPLETE(완료), CANCEL(취소)
    
    -- 접수 정보
    RECEIPT_DT      DATETIME DEFAULT GETDATE(),
    REQUESTER_NM    NVARCHAR(50) NULL,                  -- 요청자
    REQUESTER_DEPT  INT NULL,
    SYMPTOM         NVARCHAR(500) NULL,                 -- 증상/민원내용
    
    -- 처리 정보
    COMPLETE_DT     DATETIME NULL,
    REPAIR_CONTENT  NVARCHAR(500) NULL,                 -- 처리내용
    REPAIR_COST     INT NULL,                           -- 수리비용
    REPLACED_PARTS  NVARCHAR(200) NULL,                 -- 교체부품
    
    WORKER_ID       VARCHAR(20) NULL,                   -- 처리자
    REMARK          NVARCHAR(500) NULL,
    
    CREATE_DT       DATETIME DEFAULT GETDATE(),
    
    CONSTRAINT FK_REPAIR_ASSET FOREIGN KEY (ASSET_ID) REFERENCES TB_ASSET(ASSET_ID)
);

CREATE INDEX IX_REPAIR_ASSET ON TB_REPAIR_HIST(ASSET_ID);
CREATE INDEX IX_REPAIR_DT ON TB_REPAIR_HIST(RECEIPT_DT);
CREATE INDEX IX_REPAIR_STATUS ON TB_REPAIR_HIST(REPAIR_STATUS);

-- 3-3. 점검 이력
CREATE TABLE TB_CHECK_HIST (
    CHECK_ID        INT IDENTITY(1,1) PRIMARY KEY,
    
    CHECK_TYPE      VARCHAR(20) NOT NULL,               -- DEPT(부서점검), SINGLE(단건), BATCH(일괄)
    CHECK_DT        DATETIME DEFAULT GETDATE(),
    
    -- 점검 범위
    TARGET_DEPT_ID  INT NULL,                           -- 점검 대상 부서
    
    -- 점검 결과
    TOTAL_COUNT     INT DEFAULT 0,                      -- 점검 대상
    CHECKED_COUNT   INT DEFAULT 0,                      -- 확인된 수
    MISSING_COUNT   INT DEFAULT 0,                      -- 누락 수
    NEW_FOUND_COUNT INT DEFAULT 0,                      -- 미등록 발견 수
    
    WORKER_ID       VARCHAR(20) NULL,
    REMARK          NVARCHAR(500) NULL,
    
    CREATE_DT       DATETIME DEFAULT GETDATE()
);

-- 3-4. 점검 상세 (개별 자산 점검 결과)
CREATE TABLE TB_CHECK_DETAIL (
    DETAIL_ID       INT IDENTITY(1,1) PRIMARY KEY,
    CHECK_ID        INT NOT NULL,
    ASSET_ID        INT NULL,                           -- 미등록이면 NULL
    
    SERIAL_NO       VARCHAR(50) NOT NULL,               -- 스캔된 시리얼
    CHECK_RESULT    VARCHAR(20) NOT NULL,               -- MATCH(일치), MISSING(누락), NEW(미등록), WRONG_LOCATION(위치불일치)
    
    SCANNED_DT      DATETIME DEFAULT GETDATE(),
    PHOTO_PATH      VARCHAR(200) NULL,                  -- 촬영 사진 경로
    REMARK          NVARCHAR(200) NULL,
    
    CONSTRAINT FK_CHECKDETAIL_CHECK FOREIGN KEY (CHECK_ID) REFERENCES TB_CHECK_HIST(CHECK_ID)
);

CREATE INDEX IX_CHECKDETAIL_CHECK ON TB_CHECK_DETAIL(CHECK_ID);
CREATE INDEX IX_CHECKDETAIL_ASSET ON TB_CHECK_DETAIL(ASSET_ID);


-- ============================================================
-- 4. 사용자/IP 추적 테이블
-- ============================================================

-- 4-1. IP 할당 정보
CREATE TABLE TB_IP_ALLOCATION (
    IP_ID           INT IDENTITY(1,1) PRIMARY KEY,
    IP_ADDRESS      VARCHAR(15) NOT NULL UNIQUE,
    
    -- 할당 정보
    ASSET_ID        INT NULL,                           -- 할당된 자산
    DEPT_ID         INT NULL,                           -- 할당된 부서
    
    -- IP 분류
    IP_RANGE_CD     VARCHAR(20) NULL,                   -- IP 대역 코드 (건물/부서 기준)
    IP_TYPE         VARCHAR(20) DEFAULT 'FIXED',        -- FIXED(고정), DHCP(유동)
    
    ALLOC_DT        DATE NULL,                          -- 할당일
    USE_YN          CHAR(1) DEFAULT 'Y',
    REMARK          NVARCHAR(200) NULL,
    
    CONSTRAINT FK_IPALLOC_ASSET FOREIGN KEY (ASSET_ID) REFERENCES TB_ASSET(ASSET_ID)
);

-- 4-2. IP-사용자 접속 로그 (학사시스템 연동)
CREATE TABLE TB_IP_ACCESS_LOG (
    LOG_ID          BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    IP_ADDRESS      VARCHAR(15) NOT NULL,
    USER_ID         VARCHAR(20) NOT NULL,               -- 로그인한 사용자 ID
    USER_NM         NVARCHAR(50) NULL,
    
    ACCESS_DT       DATETIME NOT NULL,
    ACCESS_TYPE     VARCHAR(20) NULL,                   -- LOGIN, LOGOUT, PAGE_ACCESS
    SOURCE_SYSTEM   VARCHAR(20) NULL,                   -- ACADEMIC(학사), LMS, SSO 등
    
    CREATE_DT       DATETIME DEFAULT GETDATE()
);

-- 파티션 또는 아카이브 필요 (대용량)
CREATE INDEX IX_IPLOG_IP ON TB_IP_ACCESS_LOG(IP_ADDRESS);
CREATE INDEX IX_IPLOG_USER ON TB_IP_ACCESS_LOG(USER_ID);
CREATE INDEX IX_IPLOG_DT ON TB_IP_ACCESS_LOG(ACCESS_DT);

-- 4-3. 사용자별 IP 사용 통계 (집계 테이블)
CREATE TABLE TB_USER_IP_STATS (
    STAT_ID         INT IDENTITY(1,1) PRIMARY KEY,
    
    USER_ID         VARCHAR(20) NOT NULL,
    STAT_MONTH      CHAR(7) NOT NULL,                   -- 2026-01
    
    -- 통계
    TOTAL_ACCESS    INT DEFAULT 0,                      -- 총 접속 횟수
    UNIQUE_IP_COUNT INT DEFAULT 0,                      -- 사용한 고유 IP 수
    PRIMARY_IP      VARCHAR(15) NULL,                   -- 주 사용 IP
    PRIMARY_IP_RATIO DECIMAL(5,2) NULL,                 -- 주 사용 IP 비율
    
    -- 변화 감지
    NEW_IP_DETECTED CHAR(1) DEFAULT 'N',                -- 새로운 IP 감지 여부
    
    CREATE_DT       DATETIME DEFAULT GETDATE()
);

CREATE UNIQUE INDEX IX_USERIPSTAT_UK ON TB_USER_IP_STATS(USER_ID, STAT_MONTH);


-- ============================================================
-- 5. 외부 연동 테이블
-- ============================================================

-- 5-1. V3 연동 데이터 (안랩 업로드)
CREATE TABLE TB_V3_SYNC_DATA (
    SYNC_ID         INT IDENTITY(1,1) PRIMARY KEY,
    
    -- V3에서 제공하는 정보
    PC_NAME         VARCHAR(50) NULL,
    IP_ADDRESS      VARCHAR(15) NULL,
    MAC_ADDRESS     VARCHAR(17) NULL,
    
    OS_VERSION      NVARCHAR(100) NULL,
    OFFICE_VERSION  NVARCHAR(100) NULL,
    
    LAST_BOOT_DT    DATETIME NULL,                      -- 마지막 부팅
    LAST_UPDATE_DT  DATETIME NULL,                      -- V3 마지막 업데이트
    V3_VERSION      VARCHAR(20) NULL,
    
    -- 매칭 결과
    MATCHED_ASSET_ID INT NULL,                          -- 매칭된 자산 ID
    MATCH_STATUS    VARCHAR(20) DEFAULT 'PENDING',      -- MATCHED, UNMATCHED, CONFLICT
    
    UPLOAD_DT       DATETIME DEFAULT GETDATE(),
    UPLOAD_FILE_NM  VARCHAR(100) NULL,
    
    CONSTRAINT FK_V3SYNC_ASSET FOREIGN KEY (MATCHED_ASSET_ID) REFERENCES TB_ASSET(ASSET_ID)
);

CREATE INDEX IX_V3SYNC_PCNAME ON TB_V3_SYNC_DATA(PC_NAME);
CREATE INDEX IX_V3SYNC_MAC ON TB_V3_SYNC_DATA(MAC_ADDRESS);
CREATE INDEX IX_V3SYNC_IP ON TB_V3_SYNC_DATA(IP_ADDRESS);

-- 5-2. 엑셀 업로드 이력
CREATE TABLE TB_EXCEL_UPLOAD_HIST (
    UPLOAD_ID       INT IDENTITY(1,1) PRIMARY KEY,
    
    UPLOAD_TYPE     VARCHAR(20) NOT NULL,               -- ASSET(자산), V3, DELIVERY(납품)
    FILE_NM         NVARCHAR(200) NOT NULL,
    FILE_PATH       VARCHAR(300) NULL,
    
    -- 처리 결과
    TOTAL_ROWS      INT DEFAULT 0,
    SUCCESS_ROWS    INT DEFAULT 0,
    ERROR_ROWS      INT DEFAULT 0,
    
    PROCESS_STATUS  VARCHAR(20) DEFAULT 'PENDING',      -- PENDING, PROCESSING, COMPLETE, ERROR
    ERROR_MSG       NVARCHAR(500) NULL,
    
    CREATE_USER     VARCHAR(20) NULL,
    CREATE_DT       DATETIME DEFAULT GETDATE(),
    COMPLETE_DT     DATETIME NULL
);

-- 5-3. 엑셀 업로드 상세 (매핑 전 임시 저장)
CREATE TABLE TB_EXCEL_UPLOAD_TEMP (
    TEMP_ID         INT IDENTITY(1,1) PRIMARY KEY,
    UPLOAD_ID       INT NOT NULL,
    ROW_NO          INT NOT NULL,
    
    -- 원본 데이터 (동적 컬럼)
    COL_01          NVARCHAR(500) NULL,
    COL_02          NVARCHAR(500) NULL,
    COL_03          NVARCHAR(500) NULL,
    COL_04          NVARCHAR(500) NULL,
    COL_05          NVARCHAR(500) NULL,
    COL_06          NVARCHAR(500) NULL,
    COL_07          NVARCHAR(500) NULL,
    COL_08          NVARCHAR(500) NULL,
    COL_09          NVARCHAR(500) NULL,
    COL_10          NVARCHAR(500) NULL,
    
    -- 처리 상태
    PROCESS_STATUS  VARCHAR(20) DEFAULT 'PENDING',
    ERROR_MSG       NVARCHAR(200) NULL,
    
    CONSTRAINT FK_EXCELTEMP_UPLOAD FOREIGN KEY (UPLOAD_ID) 
        REFERENCES TB_EXCEL_UPLOAD_HIST(UPLOAD_ID)
);


-- ============================================================
-- 6. 알림/모니터링 테이블
-- ============================================================

-- 6-1. 알림 설정
CREATE TABLE TB_ALERT_CONFIG (
    CONFIG_ID       INT IDENTITY(1,1) PRIMARY KEY,
    
    ALERT_TYPE      VARCHAR(30) NOT NULL,               -- EXPIRE_SOON(만료임박), NO_V3_LOG(V3로그없음), NO_ACCESS(미접속)
    ALERT_NM        NVARCHAR(100) NOT NULL,
    
    -- 조건
    THRESHOLD_DAYS  INT NULL,                           -- 기준 일수
    THRESHOLD_VALUE INT NULL,                           -- 기준 값
    
    USE_YN          CHAR(1) DEFAULT 'Y',
    CREATE_DT       DATETIME DEFAULT GETDATE()
);

-- 6-2. 발생 알림 (점검 포인트)
CREATE TABLE TB_ALERT_LOG (
    ALERT_ID        INT IDENTITY(1,1) PRIMARY KEY,
    CONFIG_ID       INT NOT NULL,
    ASSET_ID        INT NULL,
    
    ALERT_DT        DATETIME DEFAULT GETDATE(),
    ALERT_MSG       NVARCHAR(500) NULL,
    
    -- 처리
    IS_RESOLVED     CHAR(1) DEFAULT 'N',
    RESOLVED_DT     DATETIME NULL,
    RESOLVED_USER   VARCHAR(20) NULL,
    RESOLVED_NOTE   NVARCHAR(200) NULL,
    
    CONSTRAINT FK_ALERTLOG_CONFIG FOREIGN KEY (CONFIG_ID) REFERENCES TB_ALERT_CONFIG(CONFIG_ID),
    CONSTRAINT FK_ALERTLOG_ASSET FOREIGN KEY (ASSET_ID) REFERENCES TB_ASSET(ASSET_ID)
);

CREATE INDEX IX_ALERTLOG_ASSET ON TB_ALERT_LOG(ASSET_ID);
CREATE INDEX IX_ALERTLOG_RESOLVED ON TB_ALERT_LOG(IS_RESOLVED);


-- ============================================================
-- 7. 시스템 테이블
-- ============================================================

-- 7-1. 공통 코드
CREATE TABLE TB_COMMON_CODE (
    CODE_ID         INT IDENTITY(1,1) PRIMARY KEY,
    CODE_GROUP      VARCHAR(30) NOT NULL,
    CODE_CD         VARCHAR(30) NOT NULL,
    CODE_NM         NVARCHAR(100) NOT NULL,
    CODE_DESC       NVARCHAR(200) NULL,
    SORT_ORDER      INT DEFAULT 0,
    USE_YN          CHAR(1) DEFAULT 'Y',
    
    CONSTRAINT UK_COMMONCODE UNIQUE (CODE_GROUP, CODE_CD)
);

-- 7-2. 사용자 (관리자)
CREATE TABLE TB_ADMIN_USER (
    ADMIN_ID        INT IDENTITY(1,1) PRIMARY KEY,
    USER_ID         VARCHAR(20) NOT NULL UNIQUE,
    USER_NM         NVARCHAR(50) NOT NULL,
    USER_PWD        VARCHAR(200) NOT NULL,              -- 암호화 저장
    
    DEPT_ID         INT NULL,
    ROLE_CD         VARCHAR(20) NOT NULL DEFAULT 'USER', -- ADMIN, MANAGER, USER
    
    LAST_LOGIN_DT   DATETIME NULL,
    USE_YN          CHAR(1) DEFAULT 'Y',
    CREATE_DT       DATETIME DEFAULT GETDATE()
);


-- ============================================================
-- 8. 초기 데이터
-- ============================================================

-- 장비 유형
INSERT INTO TB_ASSET_TYPE (TYPE_CD, TYPE_NM, TYPE_CATEGORY, DEFAULT_LIFESPAN_MONTHS) VALUES
('PC', '데스크탑', 'HW', 60),
('NOTEBOOK', '노트북', 'HW', 48),
('MONITOR', '모니터', 'HW', 72),
('PRINTER', '프린터', 'HW', 60),
('SCANNER', '스캐너', 'HW', 60),
('SERVER', '서버', 'HW', 84),
('NETWORK', '네트워크장비', 'HW', 60),
('ETC', '기타', 'HW', 60);

-- 제조사
INSERT INTO TB_MANUFACTURER (MFR_CD, MFR_NM) VALUES
('DELL', 'DELL'),
('HP', 'HP'),
('SAMSUNG', '삼성'),
('LG', 'LG'),
('LENOVO', 'Lenovo'),
('ASUS', 'ASUS'),
('ACER', 'Acer'),
('APPLE', 'Apple'),
('ETC', '기타');

-- 공통 코드
INSERT INTO TB_COMMON_CODE (CODE_GROUP, CODE_CD, CODE_NM, SORT_ORDER) VALUES
-- 자산 상태
('ASSET_STATUS', 'NORMAL', '정상', 1),
('ASSET_STATUS', 'CHECK_NEEDED', '점검필요', 2),
('ASSET_STATUS', 'ISSUE', '이상', 3),
('ASSET_STATUS', 'DISPOSED', '폐기', 4),
('ASSET_STATUS', 'LOST', '분실', 5),
-- 이동 유형
('MOVE_TYPE', 'RECEIVE', '입고', 1),
('MOVE_TYPE', 'MOVE', '이동', 2),
('MOVE_TYPE', 'DISPOSE', '폐기', 3),
('MOVE_TYPE', 'REPAIR_IN', '수리입고', 4),
('MOVE_TYPE', 'REPAIR_OUT', '수리출고', 5),
-- 점검 결과
('CHECK_RESULT', 'MATCH', '일치', 1),
('CHECK_RESULT', 'MISSING', '누락', 2),
('CHECK_RESULT', 'NEW', '미등록', 3),
('CHECK_RESULT', 'WRONG_LOCATION', '위치불일치', 4);

-- 알림 설정
INSERT INTO TB_ALERT_CONFIG (ALERT_TYPE, ALERT_NM, THRESHOLD_DAYS) VALUES
('EXPIRE_SOON', '사용연한 만료 임박', 90),
('NO_V3_LOG', 'V3 로그 없음', 30),
('NO_ACCESS', '학사시스템 미접속', 90),
('NO_CHECK', '미점검 장비', 180);


-- ============================================================
-- 9. 유용한 뷰 (View)
-- ============================================================

-- 9-1. 자산 전체 현황 뷰
CREATE VIEW VW_ASSET_FULL AS
SELECT 
    a.ASSET_ID,
    a.ASSET_CD,
    a.SERIAL_NO,
    a.STATUS,
    
    -- 모델 정보
    m.MODEL_NM,
    mf.MFR_NM,
    t.TYPE_NM,
    m.SPEC_RAM_GB AS MODEL_RAM,
    
    -- 실제 스펙
    a.ACTUAL_RAM_GB,
    a.OS_VERSION,
    a.OFFICE_VERSION,
    a.HANGUL_VERSION,
    
    -- 위치
    d.DEPT_NM,
    a.USER_NM,
    a.USER_ID,
    
    -- 네트워크
    a.IP_ADDRESS,
    a.MAC_ADDRESS,
    a.PC_NAME,
    
    -- 수명주기
    a.PURCHASE_DATE,
    a.EXPIRE_DATE,
    DATEDIFF(DAY, GETDATE(), a.EXPIRE_DATE) AS DAYS_TO_EXPIRE,
    
    -- 점검
    a.LAST_CHECK_DT,
    DATEDIFF(DAY, a.LAST_CHECK_DT, GETDATE()) AS DAYS_SINCE_CHECK,
    
    a.CREATE_DT
FROM TB_ASSET a
LEFT JOIN TB_MODEL m ON a.MODEL_ID = m.MODEL_ID
LEFT JOIN TB_MANUFACTURER mf ON m.MFR_ID = mf.MFR_ID
LEFT JOIN TB_ASSET_TYPE t ON a.TYPE_ID = t.TYPE_ID
LEFT JOIN TB_DEPARTMENT d ON a.DEPT_ID = d.DEPT_ID
WHERE a.USE_YN = 'Y';

-- 9-2. 만료 임박 자산 뷰
CREATE VIEW VW_ASSET_EXPIRE_SOON AS
SELECT *
FROM VW_ASSET_FULL
WHERE DAYS_TO_EXPIRE BETWEEN 0 AND 90;

-- 9-3. 점검 필요 자산 뷰
CREATE VIEW VW_ASSET_CHECK_NEEDED AS
SELECT *
FROM VW_ASSET_FULL
WHERE DAYS_SINCE_CHECK > 180
   OR LAST_CHECK_DT IS NULL;

-- 9-4. 모델별 고장 통계 뷰
CREATE VIEW VW_MODEL_ISSUE_STATS AS
SELECT 
    m.MODEL_ID,
    m.MODEL_NM,
    mf.MFR_NM,
    m.TOTAL_COUNT,
    m.ISSUE_COUNT,
    CASE WHEN m.TOTAL_COUNT > 0 
         THEN CAST(m.ISSUE_COUNT AS DECIMAL(10,2)) / m.TOTAL_COUNT * 100 
         ELSE 0 END AS ISSUE_RATE,
    (SELECT COUNT(*) FROM TB_REPAIR_HIST r 
     JOIN TB_ASSET a ON r.ASSET_ID = a.ASSET_ID 
     WHERE a.MODEL_ID = m.MODEL_ID 
       AND r.RECEIPT_DT >= DATEADD(MONTH, -6, GETDATE())) AS RECENT_REPAIR_COUNT
FROM TB_MODEL m
JOIN TB_MANUFACTURER mf ON m.MFR_ID = mf.MFR_ID;

-- 9-5. 부서별 자산 현황 뷰
CREATE VIEW VW_DEPT_ASSET_SUMMARY AS
SELECT 
    d.DEPT_ID,
    d.DEPT_NM,
    d.DEPT_LEVEL,
    d.PARENT_DEPT_ID,
    COUNT(a.ASSET_ID) AS TOTAL_COUNT,
    SUM(CASE WHEN a.STATUS = 'NORMAL' THEN 1 ELSE 0 END) AS NORMAL_COUNT,
    SUM(CASE WHEN a.STATUS = 'CHECK_NEEDED' THEN 1 ELSE 0 END) AS CHECK_NEEDED_COUNT,
    SUM(CASE WHEN a.STATUS = 'ISSUE' THEN 1 ELSE 0 END) AS ISSUE_COUNT,
    MAX(a.LAST_CHECK_DT) AS LAST_CHECK_DT
FROM TB_DEPARTMENT d
LEFT JOIN TB_ASSET a ON d.DEPT_ID = a.DEPT_ID AND a.USE_YN = 'Y'
WHERE d.USE_YN = 'Y'
GROUP BY d.DEPT_ID, d.DEPT_NM, d.DEPT_LEVEL, d.PARENT_DEPT_ID;
