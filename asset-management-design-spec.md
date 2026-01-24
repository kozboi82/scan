# 서정대학교 자산관리 시스템 설계서

## 📋 요구사항 분석 요약

### 핵심 기능 9가지
| # | 기능 | 핵심 키워드 |
|---|------|------------|
| 1 | 사용기한 도래 확인 | HW 연한, SW 지원종료, 스펙 미달 검색 |
| 2 | 부서별 보유현황 | 건물-층-부서-팀 계층, S/N 매칭 |
| 3 | S/N으로 이력 조회 | 이동내역, 수리내역, 사용자 이력 |
| 4 | 모델별 통계 | 민원횟수, 고장률, 문제 패턴 |
| 5 | IP별 사용자 조회 | 로그인 기록 매칭, 사용자 변동 감지 |
| 6 | 사용자별 IP 패턴 | 다중 기기 사용, 이상 패턴 탐지 |
| 7 | 사용여부 체크 | 학사시스템 연동, Ping 테스트 |
| 8 | 모바일 앱 점검 | 사진촬영, 위치이동, 입고/출고/수리 |
| 9 | V3 데이터 연동 | 보안로그 업로드, 사용여부 교차검증 |

---

## 🗄️ 데이터베이스 스키마 설계

### ERD 개요
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Location   │────<│   Asset     │>────│   Model     │
│  (위치)     │     │  (자산)     │     │  (모델)     │
└─────────────┘     └──────┬──────┘     └─────────────┘
                          │
         ┌────────────────┼────────────────┐
         │                │                │
         ▼                ▼                ▼
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│ AssetHistory│   │   Repair    │   │  Software   │
│ (이동이력)  │   │  (수리)     │   │ (SW현황)    │
└─────────────┘   └─────────────┘   └─────────────┘

┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    User     │────<│  LoginLog   │>────│  IPAddress  │
│  (사용자)   │     │ (로그인)    │     │  (IP정보)   │
└─────────────┘     └─────────────┘     └─────────────┘

┌─────────────┐     ┌─────────────┐
│  V3Log      │     │  Complaint  │
│ (보안로그)  │     │  (민원)     │
└─────────────┘     └─────────────┘
```

---

### 1. 위치 관리 (Location)
```sql
-- 건물-층-부서-팀 계층 구조
CREATE TABLE Location (
    LocationId      INT IDENTITY(1,1) PRIMARY KEY,
    LocationCode    NVARCHAR(20) NOT NULL UNIQUE,  -- 'BLD01-3F-IT-DEV'
    LocationName    NVARCHAR(100) NOT NULL,         -- '전산실 개발팀'
    LocationType    NVARCHAR(20) NOT NULL,          -- 'BUILDING', 'FLOOR', 'DEPT', 'TEAM'
    ParentId        INT NULL REFERENCES Location(LocationId),
    BuildingName    NVARCHAR(50),                   -- '본관'
    FloorNo         NVARCHAR(10),                   -- '3층'
    RoomNo          NVARCHAR(20),                   -- '301호'
    IPRange         NVARCHAR(50),                   -- '192.168.10.0/24' (해당 부서 IP 대역)
    ManagerUserId   INT,                            -- 담당자
    SortOrder       INT DEFAULT 0,
    IsActive        BIT DEFAULT 1,
    CreatedAt       DATETIME DEFAULT GETDATE(),
    UpdatedAt       DATETIME DEFAULT GETDATE()
);

-- 인덱스
CREATE INDEX IX_Location_Parent ON Location(ParentId);
CREATE INDEX IX_Location_Type ON Location(LocationType);
```

### 2. 모델 정보 (Model)
```sql
-- 제조사/모델별 정보 (민원/고장 통계용)
CREATE TABLE Model (
    ModelId         INT IDENTITY(1,1) PRIMARY KEY,
    ModelCode       NVARCHAR(50) NOT NULL UNIQUE,   -- 'DELL-OPTIPLEX-7090'
    ModelName       NVARCHAR(100) NOT NULL,         -- 'DELL OptiPlex 7090'
    Manufacturer    NVARCHAR(50),                   -- 'DELL'
    Category        NVARCHAR(30) NOT NULL,          -- 'DESKTOP', 'LAPTOP', 'MONITOR', 'PRINTER'
    
    -- 스펙 정보 (기능1: 스펙 미달 검색용)
    CpuSpec         NVARCHAR(100),                  -- 'Intel i5-11500'
    RamGB           INT,                            -- 16
    StorageGB       INT,                            -- 512
    StorageType     NVARCHAR(20),                   -- 'SSD', 'HDD'
    DisplayInch     DECIMAL(4,1),                   -- 24.0 (모니터용)
    Resolution      NVARCHAR(20),                   -- '1920x1080'
    
    -- 연한 정보 (기능1: 사용기한 도래)
    UsefulLifeYears INT DEFAULT 5,                  -- 내용연수 (년)
    WarrantyYears   INT DEFAULT 3,                  -- 보증기간 (년)
    
    -- 통계 (기능4: 모델별 고장률)
    TotalCount      INT DEFAULT 0,                  -- 총 보유 수량
    RepairCount     INT DEFAULT 0,                  -- 누적 수리 건수
    ComplaintCount  INT DEFAULT 0,                  -- 누적 민원 건수
    
    Notes           NVARCHAR(500),
    CreatedAt       DATETIME DEFAULT GETDATE(),
    UpdatedAt       DATETIME DEFAULT GETDATE()
);

-- 인덱스
CREATE INDEX IX_Model_Category ON Model(Category);
CREATE INDEX IX_Model_Manufacturer ON Model(Manufacturer);
```

### 3. 자산 (Asset) - 핵심 테이블
```sql
CREATE TABLE Asset (
    AssetId         INT IDENTITY(1,1) PRIMARY KEY,
    SerialNo        NVARCHAR(50) NOT NULL UNIQUE,   -- 시리얼번호 (핵심 키)
    AssetTag        NVARCHAR(30),                   -- 자산관리번호 (QR코드용)
    ModelId         INT REFERENCES Model(ModelId),
    
    -- 위치 정보 (기능2: 부서별 현황)
    LocationId      INT REFERENCES Location(LocationId),
    
    -- 네트워크 정보 (기능5,6: IP 매칭)
    IPAddress       NVARCHAR(15),                   -- '192.168.10.101'
    MacAddress      NVARCHAR(17),                   -- 'AA:BB:CC:DD:EE:FF'
    ComputerName    NVARCHAR(50),                   -- 'EDU-ADMIN-01'
    
    -- 사용자 정보
    CurrentUserId   INT,                            -- 현재 사용자
    CurrentUserName NVARCHAR(50),                   -- 사용자명 (조회 편의)
    
    -- 상태 정보
    Status          NVARCHAR(20) DEFAULT 'NORMAL',  -- NORMAL, CHECK_NEEDED, ISSUE, DISPOSED, REPAIR
    ConditionGrade  NVARCHAR(10) DEFAULT 'A',       -- A, B, C, D (상태 등급)
    
    -- 날짜 정보 (기능1: 사용기한)
    PurchaseDate    DATE,                           -- 구매일
    WarrantyEndDate DATE,                           -- 보증만료일
    DisposalDate    DATE,                           -- 폐기예정일 (구매일 + 내용연수)
    
    -- 마지막 확인 (기능7: 사용여부)
    LastCheckDate   DATE,                           -- 마지막 실사일
    LastCheckBy     INT,                            -- 실사 담당자
    LastV3LogDate   DATETIME,                       -- V3 마지막 로그 (기능9)
    LastLoginDate   DATETIME,                       -- 학사시스템 마지막 접속
    LastPingDate    DATETIME,                       -- 마지막 Ping 성공
    
    -- 입고 정보 (기능8: 입고처리)
    ReceiptDate     DATE,                           -- 입고일
    ReceiptStatus   NVARCHAR(20) DEFAULT 'RECEIVED',-- PENDING, RECEIVED, INSTALLED
    VendorName      NVARCHAR(100),                  -- 납품업체
    PurchaseOrderNo NVARCHAR(50),                   -- 발주번호
    
    -- 메모
    Notes           NVARCHAR(500),
    
    -- 감사 정보
    CreatedAt       DATETIME DEFAULT GETDATE(),
    CreatedBy       INT,
    UpdatedAt       DATETIME DEFAULT GETDATE(),
    UpdatedBy       INT
);

-- 인덱스
CREATE INDEX IX_Asset_Location ON Asset(LocationId);
CREATE INDEX IX_Asset_Model ON Asset(ModelId);
CREATE INDEX IX_Asset_Status ON Asset(Status);
CREATE INDEX IX_Asset_IP ON Asset(IPAddress);
CREATE INDEX IX_Asset_Mac ON Asset(MacAddress);
CREATE INDEX IX_Asset_ComputerName ON Asset(ComputerName);
CREATE INDEX IX_Asset_CurrentUser ON Asset(CurrentUserId);
CREATE INDEX IX_Asset_DisposalDate ON Asset(DisposalDate);
CREATE INDEX IX_Asset_WarrantyEnd ON Asset(WarrantyEndDate);
```

### 4. 소프트웨어 현황 (Software)
```sql
-- 기능1: SW 지원종료, 버전 관리
CREATE TABLE Software (
    SoftwareId      INT IDENTITY(1,1) PRIMARY KEY,
    AssetId         INT NOT NULL REFERENCES Asset(AssetId),
    SoftwareType    NVARCHAR(30) NOT NULL,          -- 'OS', 'OFFICE', 'HWP', 'ANTIVIRUS'
    SoftwareName    NVARCHAR(100) NOT NULL,         -- 'Windows 10 Pro'
    Version         NVARCHAR(50),                   -- '22H2'
    LicenseKey      NVARCHAR(100),                  -- 라이선스 키 (암호화 저장)
    LicenseType     NVARCHAR(30),                   -- 'OEM', 'VOLUME', 'RETAIL'
    
    -- 지원종료 관리 (기능1)
    SupportEndDate  DATE,                           -- 지원종료일
    IsEndOfSupport  AS (CASE WHEN SupportEndDate < GETDATE() THEN 1 ELSE 0 END), -- 계산열
    
    InstalledDate   DATE,
    LastUpdated     DATETIME,
    Notes           NVARCHAR(200),
    CreatedAt       DATETIME DEFAULT GETDATE()
);

-- 인덱스
CREATE INDEX IX_Software_Asset ON Software(AssetId);
CREATE INDEX IX_Software_Type ON Software(SoftwareType);
CREATE INDEX IX_Software_SupportEnd ON Software(SupportEndDate);
```

### 5. 자산 이력 (AssetHistory)
```sql
-- 기능3: 이동내역, 상태변경 이력
CREATE TABLE AssetHistory (
    HistoryId       INT IDENTITY(1,1) PRIMARY KEY,
    AssetId         INT NOT NULL REFERENCES Asset(AssetId),
    HistoryType     NVARCHAR(30) NOT NULL,          -- 'MOVE', 'STATUS_CHANGE', 'USER_CHANGE', 'CHECK', 'RECEIPT'
    
    -- 변경 전/후
    FromLocationId  INT REFERENCES Location(LocationId),
    ToLocationId    INT REFERENCES Location(LocationId),
    FromUserId      INT,
    ToUserId        INT,
    FromStatus      NVARCHAR(20),
    ToStatus        NVARCHAR(20),
    
    -- 상세 정보
    Description     NVARCHAR(500),
    PhotoUrl        NVARCHAR(500),                  -- 촬영 사진 URL (기능8)
    
    -- 작업자 정보
    ActionBy        INT NOT NULL,
    ActionByName    NVARCHAR(50),
    ActionAt        DATETIME DEFAULT GETDATE(),
    ActionDevice    NVARCHAR(50),                   -- 'MOBILE_APP', 'WEB'
    
    -- GPS 정보 (모바일 앱용)
    Latitude        DECIMAL(10,7),
    Longitude       DECIMAL(10,7)
);

-- 인덱스
CREATE INDEX IX_AssetHistory_Asset ON AssetHistory(AssetId);
CREATE INDEX IX_AssetHistory_Type ON AssetHistory(HistoryType);
CREATE INDEX IX_AssetHistory_Date ON AssetHistory(ActionAt);
```

### 6. 수리 내역 (Repair)
```sql
-- 기능3, 기능4: 수리내역 관리
CREATE TABLE Repair (
    RepairId        INT IDENTITY(1,1) PRIMARY KEY,
    AssetId         INT NOT NULL REFERENCES Asset(AssetId),
    
    -- 수리 분류
    RepairType      NVARCHAR(30) NOT NULL,          -- 'INTERNAL', 'EXTERNAL', 'WARRANTY'
    RepairCategory  NVARCHAR(50),                   -- 'HDD_REPLACE', 'POWER_ISSUE', 'DISPLAY', etc.
    
    -- 상태
    Status          NVARCHAR(20) DEFAULT 'RECEIVED',-- RECEIVED, IN_PROGRESS, COMPLETED, CANCELLED
    Priority        NVARCHAR(10) DEFAULT 'NORMAL',  -- LOW, NORMAL, HIGH, URGENT
    
    -- 일자
    ReceivedDate    DATETIME DEFAULT GETDATE(),     -- 입고일
    StartDate       DATETIME,                       -- 작업 시작일
    CompletedDate   DATETIME,                       -- 완료일
    
    -- 내용
    SymptomDesc     NVARCHAR(500),                  -- 증상
    DiagnosisDesc   NVARCHAR(500),                  -- 진단
    RepairDesc      NVARCHAR(500),                  -- 수리 내용
    PartsUsed       NVARCHAR(300),                  -- 사용 부품
    
    -- 비용
    LaborCost       DECIMAL(10,2) DEFAULT 0,
    PartsCost       DECIMAL(10,2) DEFAULT 0,
    TotalCost       AS (LaborCost + PartsCost),
    
    -- 사진 (기능8)
    PhotoBeforeUrl  NVARCHAR(500),                  -- 수리 전 사진
    PhotoAfterUrl   NVARCHAR(500),                  -- 수리 후 사진
    
    -- 작업자
    TechnicianId    INT,
    TechnicianName  NVARCHAR(50),
    VendorName      NVARCHAR(100),                  -- 외부 수리업체
    
    Notes           NVARCHAR(500),
    CreatedAt       DATETIME DEFAULT GETDATE(),
    UpdatedAt       DATETIME DEFAULT GETDATE()
);

-- 인덱스
CREATE INDEX IX_Repair_Asset ON Repair(AssetId);
CREATE INDEX IX_Repair_Status ON Repair(Status);
CREATE INDEX IX_Repair_Date ON Repair(ReceivedDate);

-- 수리 완료 시 Model 테이블 통계 업데이트 트리거
CREATE TRIGGER TR_Repair_UpdateModelStats
ON Repair
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE m
    SET RepairCount = (
        SELECT COUNT(*) FROM Repair r 
        JOIN Asset a ON r.AssetId = a.AssetId 
        WHERE a.ModelId = m.ModelId
    )
    FROM Model m
    WHERE m.ModelId IN (
        SELECT a.ModelId FROM Asset a
        JOIN inserted i ON a.AssetId = i.AssetId
    );
END;
```

### 7. 민원 (Complaint)
```sql
-- 기능4: 민원 관리, 모델별 통계
CREATE TABLE Complaint (
    ComplaintId     INT IDENTITY(1,1) PRIMARY KEY,
    AssetId         INT REFERENCES Asset(AssetId), -- NULL 가능 (자산 미특정 민원)
    
    -- 민원 정보
    ComplaintType   NVARCHAR(30) NOT NULL,          -- 'MALFUNCTION', 'SLOW', 'INSTALL_REQUEST', 'OTHER'
    Title           NVARCHAR(200) NOT NULL,
    Description     NVARCHAR(1000),
    
    -- 신고자
    ReporterId      INT,
    ReporterName    NVARCHAR(50),
    ReporterDept    NVARCHAR(100),
    ReporterContact NVARCHAR(50),
    
    -- 상태
    Status          NVARCHAR(20) DEFAULT 'OPEN',    -- OPEN, IN_PROGRESS, RESOLVED, CLOSED
    Priority        NVARCHAR(10) DEFAULT 'NORMAL',
    
    -- 처리
    AssignedTo      INT,
    AssignedToName  NVARCHAR(50),
    Resolution      NVARCHAR(500),
    
    -- 연결된 수리
    RepairId        INT REFERENCES Repair(RepairId),
    
    -- 일자
    ReportedAt      DATETIME DEFAULT GETDATE(),
    ResolvedAt      DATETIME,
    
    CreatedAt       DATETIME DEFAULT GETDATE()
);

-- 인덱스
CREATE INDEX IX_Complaint_Asset ON Complaint(AssetId);
CREATE INDEX IX_Complaint_Status ON Complaint(Status);
```

### 8. 사용자 (User)
```sql
CREATE TABLE [User] (
    UserId          INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeNo      NVARCHAR(20) NOT NULL UNIQUE,   -- 사번/학번
    UserName        NVARCHAR(50) NOT NULL,
    UserType        NVARCHAR(20),                   -- 'STAFF', 'FACULTY', 'ADMIN'
    DeptId          INT REFERENCES Location(LocationId),
    DeptName        NVARCHAR(100),
    Email           NVARCHAR(100),
    Phone           NVARCHAR(20),
    Position        NVARCHAR(50),                   -- 직위
    IsActive        BIT DEFAULT 1,
    CreatedAt       DATETIME DEFAULT GETDATE()
);
```

### 9. IP 주소 관리 (IPAddress)
```sql
-- 기능5, 6: IP별 관리
CREATE TABLE IPAddress (
    IPId            INT IDENTITY(1,1) PRIMARY KEY,
    IPAddress       NVARCHAR(15) NOT NULL UNIQUE,
    
    -- 할당 정보
    LocationId      INT REFERENCES Location(LocationId),
    AssetId         INT REFERENCES Asset(AssetId),
    AssignedUserId  INT REFERENCES [User](UserId),
    
    -- 분류
    IPType          NVARCHAR(20) DEFAULT 'FIXED',   -- 'FIXED', 'DHCP', 'RESERVED'
    NetworkSegment  NVARCHAR(30),                   -- '본관', '도서관', etc.
    VlanId          INT,
    
    -- 상태
    Status          NVARCHAR(20) DEFAULT 'ACTIVE',  -- ACTIVE, INACTIVE, RESERVED
    LastSeenAt      DATETIME,                       -- 마지막 활성 확인
    
    Notes           NVARCHAR(200),
    CreatedAt       DATETIME DEFAULT GETDATE(),
    UpdatedAt       DATETIME DEFAULT GETDATE()
);
```

### 10. 로그인 기록 (LoginLog)
```sql
-- 기능5, 6: IP-사용자 매칭, 패턴 분석
CREATE TABLE LoginLog (
    LogId           BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserId          INT REFERENCES [User](UserId),
    EmployeeNo      NVARCHAR(20),                   -- 빠른 조회용 중복 저장
    
    -- 접속 정보
    IPAddress       NVARCHAR(15) NOT NULL,
    ComputerName    NVARCHAR(50),
    
    -- 시스템
    SystemType      NVARCHAR(30),                   -- 'ACADEMIC', 'PORTAL', 'LIBRARY', etc.
    
    -- 시간
    LoginAt         DATETIME DEFAULT GETDATE(),
    LogoutAt        DATETIME,
    
    -- 분석용
    IsFirstLogin    BIT DEFAULT 0,                  -- 해당 IP에서 첫 로그인 여부
    IsNewIP         BIT DEFAULT 0                   -- 사용자의 새로운 IP 여부
);

-- 인덱스 (대용량 테이블)
CREATE INDEX IX_LoginLog_User ON LoginLog(UserId);
CREATE INDEX IX_LoginLog_IP ON LoginLog(IPAddress);
CREATE INDEX IX_LoginLog_Date ON LoginLog(LoginAt);
CREATE INDEX IX_LoginLog_UserIP ON LoginLog(UserId, IPAddress);

-- 파티션 고려 (월별)
```

### 11. V3 로그 (V3Log)
```sql
-- 기능9: V3 데이터 연동
CREATE TABLE V3Log (
    V3LogId         BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- V3에서 제공하는 정보
    ComputerName    NVARCHAR(50),
    IPAddress       NVARCHAR(15),
    MacAddress      NVARCHAR(17),
    
    -- 상태 정보
    V3Version       NVARCHAR(30),
    EngineVersion   NVARCHAR(30),
    LastUpdateDate  DATETIME,                       -- 엔진 업데이트일
    LastScanDate    DATETIME,                       -- 마지막 검사일
    
    -- 시스템 정보
    OSName          NVARCHAR(100),
    OSVersion       NVARCHAR(50),
    
    -- 매칭된 자산
    AssetId         INT REFERENCES Asset(AssetId),
    MatchStatus     NVARCHAR(20),                   -- 'MATCHED', 'UNMATCHED', 'MULTIPLE'
    
    -- 업로드 정보
    UploadBatchId   NVARCHAR(50),                   -- 업로드 배치 ID
    UploadedAt      DATETIME DEFAULT GETDATE(),
    UploadedBy      INT,
    
    -- 분석 결과
    IsActive        BIT,                            -- 최근 활동 여부
    DaysSinceLastSeen INT,                          -- 마지막 확인 후 경과일
    AlertFlag       BIT DEFAULT 0                   -- 점검 필요 플래그
);

-- 인덱스
CREATE INDEX IX_V3Log_Computer ON V3Log(ComputerName);
CREATE INDEX IX_V3Log_IP ON V3Log(IPAddress);
CREATE INDEX IX_V3Log_Mac ON V3Log(MacAddress);
CREATE INDEX IX_V3Log_Asset ON V3Log(AssetId);
CREATE INDEX IX_V3Log_Batch ON V3Log(UploadBatchId);
```

### 12. 실사 조사 (Inspection)
```sql
-- 기능8: 모바일 앱 점검
CREATE TABLE Inspection (
    InspectionId    INT IDENTITY(1,1) PRIMARY KEY,
    
    -- 조사 정보
    InspectionType  NVARCHAR(30) NOT NULL,          -- 'REGULAR', 'SPOT', 'INVENTORY'
    LocationId      INT NOT NULL REFERENCES Location(LocationId),
    
    -- 상태
    Status          NVARCHAR(20) DEFAULT 'IN_PROGRESS', -- IN_PROGRESS, COMPLETED, CANCELLED
    
    -- 일자
    StartedAt       DATETIME DEFAULT GETDATE(),
    CompletedAt     DATETIME,
    
    -- 결과
    TotalExpected   INT DEFAULT 0,                  -- 예상 수량
    TotalFound      INT DEFAULT 0,                  -- 확인 수량
    TotalMissing    INT DEFAULT 0,                  -- 누락 수량
    TotalNew        INT DEFAULT 0,                  -- 신규 발견
    TotalMoved      INT DEFAULT 0,                  -- 위치 이동
    
    -- 담당자
    InspectorId     INT NOT NULL,
    InspectorName   NVARCHAR(50),
    
    Notes           NVARCHAR(500),
    CreatedAt       DATETIME DEFAULT GETDATE()
);

-- 실사 상세
CREATE TABLE InspectionDetail (
    DetailId        INT IDENTITY(1,1) PRIMARY KEY,
    InspectionId    INT NOT NULL REFERENCES Inspection(InspectionId),
    AssetId         INT REFERENCES Asset(AssetId),
    SerialNo        NVARCHAR(50),                   -- 신규 발견 시 AssetId 없을 수 있음
    
    -- 결과
    ResultType      NVARCHAR(20) NOT NULL,          -- 'FOUND', 'MISSING', 'NEW', 'MOVED_IN', 'MOVED_OUT'
    FromLocationId  INT REFERENCES Location(LocationId),
    
    -- 사진
    PhotoUrl        NVARCHAR(500),
    
    -- OCR 결과 (사진 촬영 시)
    OcrRawText      NVARCHAR(500),
    OcrConfidence   DECIMAL(5,2),
    
    CheckedAt       DATETIME DEFAULT GETDATE(),
    Notes           NVARCHAR(200)
);

-- 인덱스
CREATE INDEX IX_InspectionDetail_Inspection ON InspectionDetail(InspectionId);
CREATE INDEX IX_InspectionDetail_Asset ON InspectionDetail(AssetId);
```

---

## 📊 주요 뷰 (View) 설계

### 1. 사용기한 도래 자산 뷰 (기능1)
```sql
CREATE VIEW VW_ExpiringAssets AS
SELECT 
    a.AssetId,
    a.SerialNo,
    m.ModelName,
    m.Category,
    l.LocationName,
    a.CurrentUserName,
    a.PurchaseDate,
    a.DisposalDate,
    a.WarrantyEndDate,
    DATEDIFF(DAY, GETDATE(), a.DisposalDate) AS DaysToDisposal,
    DATEDIFF(DAY, GETDATE(), a.WarrantyEndDate) AS DaysToWarrantyEnd,
    CASE 
        WHEN a.DisposalDate < GETDATE() THEN 'EXPIRED'
        WHEN a.DisposalDate < DATEADD(MONTH, 6, GETDATE()) THEN 'EXPIRING_SOON'
        ELSE 'OK'
    END AS DisposalStatus
FROM Asset a
JOIN Model m ON a.ModelId = m.ModelId
JOIN Location l ON a.LocationId = l.LocationId
WHERE a.Status != 'DISPOSED';
```

### 2. SW 지원종료 현황 뷰 (기능1)
```sql
CREATE VIEW VW_EndOfSupportSoftware AS
SELECT 
    a.AssetId,
    a.SerialNo,
    m.ModelName,
    l.LocationName,
    s.SoftwareType,
    s.SoftwareName,
    s.Version,
    s.SupportEndDate,
    DATEDIFF(DAY, GETDATE(), s.SupportEndDate) AS DaysToEOS,
    CASE 
        WHEN s.SupportEndDate < GETDATE() THEN 'END_OF_SUPPORT'
        WHEN s.SupportEndDate < DATEADD(MONTH, 6, GETDATE()) THEN 'EOS_SOON'
        ELSE 'SUPPORTED'
    END AS SupportStatus
FROM Software s
JOIN Asset a ON s.AssetId = a.AssetId
JOIN Model m ON a.ModelId = m.ModelId
JOIN Location l ON a.LocationId = l.LocationId
WHERE a.Status != 'DISPOSED';
```

### 3. 스펙 미달 자산 뷰 (기능1 - Win11 최소사양 등)
```sql
CREATE VIEW VW_BelowSpecAssets AS
SELECT 
    a.AssetId,
    a.SerialNo,
    m.ModelName,
    m.RamGB,
    m.CpuSpec,
    l.LocationName,
    a.CurrentUserName,
    'RAM_BELOW_8GB' AS IssueType
FROM Asset a
JOIN Model m ON a.ModelId = m.ModelId
JOIN Location l ON a.LocationId = l.LocationId
WHERE m.RamGB < 8 AND m.Category IN ('DESKTOP', 'LAPTOP')
  AND a.Status = 'NORMAL'

UNION ALL

SELECT 
    a.AssetId,
    a.SerialNo,
    m.ModelName,
    m.RamGB,
    m.CpuSpec,
    l.LocationName,
    a.CurrentUserName,
    'NO_TPM_FOR_WIN11' AS IssueType
FROM Asset a
JOIN Model m ON a.ModelId = m.ModelId
JOIN Location l ON a.LocationId = l.LocationId
JOIN Software s ON a.AssetId = s.AssetId
WHERE s.SoftwareType = 'OS' 
  AND s.SoftwareName LIKE '%Windows 10%'
  AND m.RamGB < 4
  AND a.Status = 'NORMAL';
```

### 4. 부서별 보유현황 뷰 (기능2)
```sql
CREATE VIEW VW_LocationAssetSummary AS
SELECT 
    l.LocationId,
    l.LocationCode,
    l.LocationName,
    l.LocationType,
    l.ParentId,
    l.BuildingName,
    l.FloorNo,
    COUNT(a.AssetId) AS TotalAssets,
    SUM(CASE WHEN a.Status = 'NORMAL' THEN 1 ELSE 0 END) AS NormalCount,
    SUM(CASE WHEN a.Status = 'CHECK_NEEDED' THEN 1 ELSE 0 END) AS CheckNeededCount,
    SUM(CASE WHEN a.Status = 'ISSUE' THEN 1 ELSE 0 END) AS IssueCount,
    SUM(CASE WHEN a.Status = 'REPAIR' THEN 1 ELSE 0 END) AS RepairCount,
    MAX(a.LastCheckDate) AS LastInspectionDate
FROM Location l
LEFT JOIN Asset a ON l.LocationId = a.LocationId
GROUP BY l.LocationId, l.LocationCode, l.LocationName, l.LocationType, 
         l.ParentId, l.BuildingName, l.FloorNo;
```

### 5. 모델별 고장률 뷰 (기능4)
```sql
CREATE VIEW VW_ModelReliability AS
SELECT 
    m.ModelId,
    m.ModelCode,
    m.ModelName,
    m.Manufacturer,
    m.Category,
    m.TotalCount,
    m.RepairCount,
    m.ComplaintCount,
    CASE WHEN m.TotalCount > 0 
         THEN CAST(m.RepairCount AS DECIMAL(5,2)) / m.TotalCount * 100 
         ELSE 0 
    END AS RepairRate,
    CASE WHEN m.TotalCount > 0 
         THEN CAST(m.ComplaintCount AS DECIMAL(5,2)) / m.TotalCount * 100 
         ELSE 0 
    END AS ComplaintRate,
    (SELECT TOP 1 RepairCategory 
     FROM Repair r 
     JOIN Asset a ON r.AssetId = a.AssetId 
     WHERE a.ModelId = m.ModelId 
     GROUP BY RepairCategory 
     ORDER BY COUNT(*) DESC) AS MostCommonIssue
FROM Model m
WHERE m.TotalCount > 0;
```

### 6. IP-사용자 매칭 이상 감지 뷰 (기능5, 6)
```sql
CREATE VIEW VW_IPUserAnomalies AS
WITH UserIPStats AS (
    SELECT 
        UserId,
        EmployeeNo,
        IPAddress,
        COUNT(*) AS LoginCount,
        MIN(LoginAt) AS FirstLogin,
        MAX(LoginAt) AS LastLogin,
        ROW_NUMBER() OVER (PARTITION BY UserId ORDER BY COUNT(*) DESC) AS IPRank
    FROM LoginLog
    WHERE LoginAt > DATEADD(MONTH, -3, GETDATE())
    GROUP BY UserId, EmployeeNo, IPAddress
),
IPUserStats AS (
    SELECT 
        IPAddress,
        COUNT(DISTINCT UserId) AS UniqueUsers,
        STRING_AGG(CAST(UserId AS NVARCHAR), ',') AS UserList
    FROM LoginLog
    WHERE LoginAt > DATEADD(MONTH, -3, GETDATE())
    GROUP BY IPAddress
)
SELECT 
    u.UserId,
    u.EmployeeNo,
    usr.UserName,
    COUNT(DISTINCT u.IPAddress) AS IPCount,
    STRING_AGG(u.IPAddress, ', ') AS UsedIPs,
    CASE 
        WHEN COUNT(DISTINCT u.IPAddress) > 3 THEN 'MULTI_IP_USER'
        ELSE 'NORMAL'
    END AS UserPattern
FROM UserIPStats u
JOIN [User] usr ON u.UserId = usr.UserId
GROUP BY u.UserId, u.EmployeeNo, usr.UserName

UNION ALL

SELECT 
    NULL AS UserId,
    NULL AS EmployeeNo,
    'IP: ' + i.IPAddress AS UserName,
    i.UniqueUsers AS IPCount,
    i.UserList AS UsedIPs,
    CASE 
        WHEN i.UniqueUsers > 5 THEN 'MULTI_USER_IP'
        ELSE 'NORMAL'
    END AS UserPattern
FROM IPUserStats i
WHERE i.UniqueUsers > 1;
```

### 7. V3 연동 이상 감지 뷰 (기능9)
```sql
CREATE VIEW VW_V3Anomalies AS
SELECT 
    a.AssetId,
    a.SerialNo,
    a.ComputerName,
    a.IPAddress,
    l.LocationName,
    a.CurrentUserName,
    a.LastV3LogDate,
    DATEDIFF(DAY, a.LastV3LogDate, GETDATE()) AS DaysSinceV3,
    a.LastLoginDate,
    DATEDIFF(DAY, a.LastLoginDate, GETDATE()) AS DaysSinceLogin,
    CASE 
        WHEN a.LastV3LogDate IS NULL THEN 'NO_V3_RECORD'
        WHEN DATEDIFF(DAY, a.LastV3LogDate, GETDATE()) > 90 THEN 'V3_INACTIVE_90DAYS'
        WHEN DATEDIFF(DAY, a.LastV3LogDate, GETDATE()) > 30 THEN 'V3_INACTIVE_30DAYS'
        ELSE 'V3_ACTIVE'
    END AS V3Status,
    CASE 
        WHEN a.LastLoginDate IS NULL AND a.LastV3LogDate IS NULL THEN 'POSSIBLY_UNUSED'
        WHEN a.LastLoginDate IS NOT NULL AND a.LastV3LogDate IS NULL THEN 'V3_NOT_INSTALLED'
        ELSE 'OK'
    END AS AlertType
FROM Asset a
JOIN Location l ON a.LocationId = l.LocationId
WHERE a.Status = 'NORMAL'
  AND a.Category IN ('DESKTOP', 'LAPTOP');
```

---

## 🔧 주요 저장 프로시저

### SP_AssetSearch: 통합 검색
```sql
CREATE PROCEDURE SP_AssetSearch
    @SerialNo NVARCHAR(50) = NULL,
    @ModelName NVARCHAR(100) = NULL,
    @LocationId INT = NULL,
    @Status NVARCHAR(20) = NULL,
    @Category NVARCHAR(30) = NULL,
    @IPAddress NVARCHAR(15) = NULL,
    @UserName NVARCHAR(50) = NULL,
    @RamGBMin INT = NULL,
    @RamGBMax INT = NULL,
    @PurchaseDateFrom DATE = NULL,
    @PurchaseDateTo DATE = NULL,
    @DisposalWithinDays INT = NULL,
    @PageNo INT = 1,
    @PageSize INT = 50
AS
BEGIN
    SELECT 
        a.*,
        m.ModelName, m.Manufacturer, m.Category, m.RamGB,
        l.LocationName, l.BuildingName, l.FloorNo
    FROM Asset a
    JOIN Model m ON a.ModelId = m.ModelId
    JOIN Location l ON a.LocationId = l.LocationId
    WHERE (@SerialNo IS NULL OR a.SerialNo LIKE '%' + @SerialNo + '%')
      AND (@ModelName IS NULL OR m.ModelName LIKE '%' + @ModelName + '%')
      AND (@LocationId IS NULL OR a.LocationId = @LocationId)
      AND (@Status IS NULL OR a.Status = @Status)
      AND (@Category IS NULL OR m.Category = @Category)
      AND (@IPAddress IS NULL OR a.IPAddress LIKE '%' + @IPAddress + '%')
      AND (@UserName IS NULL OR a.CurrentUserName LIKE '%' + @UserName + '%')
      AND (@RamGBMin IS NULL OR m.RamGB >= @RamGBMin)
      AND (@RamGBMax IS NULL OR m.RamGB <= @RamGBMax)
      AND (@PurchaseDateFrom IS NULL OR a.PurchaseDate >= @PurchaseDateFrom)
      AND (@PurchaseDateTo IS NULL OR a.PurchaseDate <= @PurchaseDateTo)
      AND (@DisposalWithinDays IS NULL OR a.DisposalDate <= DATEADD(DAY, @DisposalWithinDays, GETDATE()))
    ORDER BY a.UpdatedAt DESC
    OFFSET (@PageNo - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
```

### SP_AssetMove: 자산 이동 처리 (기능8)
```sql
CREATE PROCEDURE SP_AssetMove
    @SerialNo NVARCHAR(50),
    @ToLocationId INT,
    @ToUserId INT = NULL,
    @ActionBy INT,
    @PhotoUrl NVARCHAR(500) = NULL,
    @Notes NVARCHAR(500) = NULL
AS
BEGIN
    BEGIN TRANSACTION;
    
    DECLARE @AssetId INT, @FromLocationId INT, @FromUserId INT;
    
    -- 현재 정보 조회
    SELECT @AssetId = AssetId, @FromLocationId = LocationId, @FromUserId = CurrentUserId
    FROM Asset WHERE SerialNo = @SerialNo;
    
    IF @AssetId IS NULL
    BEGIN
        RAISERROR('자산을 찾을 수 없습니다: %s', 16, 1, @SerialNo);
        ROLLBACK;
        RETURN;
    END
    
    -- 자산 정보 업데이트
    UPDATE Asset
    SET LocationId = @ToLocationId,
        CurrentUserId = ISNULL(@ToUserId, CurrentUserId),
        LastCheckDate = CAST(GETDATE() AS DATE),
        LastCheckBy = @ActionBy,
        UpdatedAt = GETDATE(),
        UpdatedBy = @ActionBy
    WHERE AssetId = @AssetId;
    
    -- 이력 추가
    INSERT INTO AssetHistory (AssetId, HistoryType, FromLocationId, ToLocationId, 
                               FromUserId, ToUserId, Description, PhotoUrl, 
                               ActionBy, ActionDevice)
    VALUES (@AssetId, 'MOVE', @FromLocationId, @ToLocationId,
            @FromUserId, @ToUserId, @Notes, @PhotoUrl,
            @ActionBy, 'MOBILE_APP');
    
    COMMIT;
    
    SELECT 'SUCCESS' AS Result, @AssetId AS AssetId;
END;
```

### SP_ImportV3Log: V3 데이터 임포트 (기능9)
```sql
CREATE PROCEDURE SP_ImportV3Log
    @BatchId NVARCHAR(50),
    @UploadedBy INT
AS
BEGIN
    -- 임시 테이블에서 V3Log로 이동 후 자산 매칭
    
    -- 1. ComputerName으로 매칭
    UPDATE v
    SET AssetId = a.AssetId,
        MatchStatus = 'MATCHED'
    FROM V3Log v
    JOIN Asset a ON v.ComputerName = a.ComputerName
    WHERE v.UploadBatchId = @BatchId AND v.AssetId IS NULL;
    
    -- 2. MAC 주소로 매칭
    UPDATE v
    SET AssetId = a.AssetId,
        MatchStatus = 'MATCHED'
    FROM V3Log v
    JOIN Asset a ON v.MacAddress = a.MacAddress
    WHERE v.UploadBatchId = @BatchId AND v.AssetId IS NULL;
    
    -- 3. IP로 매칭 (보조)
    UPDATE v
    SET AssetId = a.AssetId,
        MatchStatus = 'MATCHED'
    FROM V3Log v
    JOIN Asset a ON v.IPAddress = a.IPAddress
    WHERE v.UploadBatchId = @BatchId AND v.AssetId IS NULL;
    
    -- 4. 매칭 안 된 것 표시
    UPDATE V3Log
    SET MatchStatus = 'UNMATCHED'
    WHERE UploadBatchId = @BatchId AND AssetId IS NULL;
    
    -- 5. 자산 테이블에 LastV3LogDate 업데이트
    UPDATE a
    SET LastV3LogDate = v.UploadedAt
    FROM Asset a
    JOIN V3Log v ON a.AssetId = v.AssetId
    WHERE v.UploadBatchId = @BatchId;
    
    -- 6. 이상 플래그 설정 (30일 이상 미접속)
    UPDATE V3Log
    SET AlertFlag = 1,
        DaysSinceLastSeen = DATEDIFF(DAY, LastScanDate, GETDATE())
    WHERE UploadBatchId = @BatchId
      AND DATEDIFF(DAY, LastScanDate, GETDATE()) > 30;
    
    -- 결과 반환
    SELECT 
        COUNT(*) AS TotalRecords,
        SUM(CASE WHEN MatchStatus = 'MATCHED' THEN 1 ELSE 0 END) AS MatchedCount,
        SUM(CASE WHEN MatchStatus = 'UNMATCHED' THEN 1 ELSE 0 END) AS UnmatchedCount,
        SUM(CASE WHEN AlertFlag = 1 THEN 1 ELSE 0 END) AS AlertCount
    FROM V3Log
    WHERE UploadBatchId = @BatchId;
END;
```

---

## 📱 화면 흐름도

### 메인 메뉴 구조
```
자산 관리
├─ 📊 대시보드 (현황 요약)
├─ 💻 자산 현황 (트리+카드)
├─ 🔍 자산 검색
├─ ➕ 자산 등록
└─ 📤 엑셀 업로드

조사/점검
├─ 📋 실사 조사
├─ 📷 모바일 점검
└─ 📑 조사 이력

수리/민원
├─ 🔧 수리 관리
├─ 📞 민원 관리
└─ 📈 모델별 통계

분석
├─ ⏰ 사용기한 도래
├─ 🖥️ SW 지원종료
├─ 💾 스펙 미달 현황
├─ 🌐 IP-사용자 분석
└─ 🛡️ V3 연동 현황

시스템
├─ 🏢 부서 관리
├─ 👤 사용자 관리
├─ 🌐 IP 관리
└─ ⚙️ 설정
```

---

## ✅ 기능별 구현 체크리스트

| # | 기능 | 관련 테이블 | 관련 뷰/SP | 우선순위 |
|---|------|------------|-----------|---------|
| 1 | 사용기한 도래 | Asset, Software, Model | VW_ExpiringAssets, VW_EndOfSupportSoftware, VW_BelowSpecAssets | ⭐⭐⭐ |
| 2 | 부서별 보유현황 | Location, Asset | VW_LocationAssetSummary | ⭐⭐⭐ |
| 3 | S/N 이력 조회 | Asset, AssetHistory, Repair | SP_AssetSearch | ⭐⭐⭐ |
| 4 | 모델별 통계 | Model, Repair, Complaint | VW_ModelReliability | ⭐⭐ |
| 5 | IP별 사용자 조회 | LoginLog, IPAddress, Asset | VW_IPUserAnomalies | ⭐⭐ |
| 6 | 사용자별 IP 패턴 | LoginLog, User | VW_IPUserAnomalies | ⭐⭐ |
| 7 | 사용여부 체크 | Asset (Ping), LoginLog, V3Log | - | ⭐⭐ |
| 8 | 모바일 앱 점검 | Inspection, InspectionDetail, AssetHistory | SP_AssetMove | ⭐⭐⭐ |
| 9 | V3 데이터 연동 | V3Log, Asset | SP_ImportV3Log, VW_V3Anomalies | ⭐⭐ |

---

## 🚀 개발 로드맵 제안

### Phase 1 (4주): 기본 자산관리
- [ ] DB 스키마 생성
- [ ] 기본 CRUD (Asset, Model, Location)
- [ ] 엑셀 업로드 (열 매핑 포함)
- [ ] 부서별 트리 + 카드 UI

### Phase 2 (4주): 이력 및 수리
- [ ] 자산 이력 관리
- [ ] 수리 관리
- [ ] 민원 관리
- [ ] 모델별 통계

### Phase 3 (4주): 모바일 + 분석
- [ ] PWA 모바일 앱
- [ ] OCR/QR 촬영
- [ ] 실사 조사 기능
- [ ] 사용기한/SW 분석

### Phase 4 (4주): 연동 + 고급
- [ ] V3 데이터 연동
- [ ] IP-사용자 분석 (학사시스템 연동)
- [ ] 대시보드 고도화
- [ ] Ping 테스트 자동화
