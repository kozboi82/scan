/**
 * Mock Data for Asset Management Mobile Check
 * 테스트용 가상 데이터 - 실제 API 연동 전 프론트엔드 시연용
 *
 * 사용법:
 *   const asset = await findAsset('40LGD5K202209000001');
 *   const delivery = await findDelivery('NEWDELL2025010007');
 */

// ============================================================
// 자산 데이터 (TB_ASSET Mock)
// ============================================================
const MOCK_ASSETS = {
    // A1-1: 정상 (같은 부서 - 교무실)
    "40LGD5K202209000001": {
        serial: "40LGD5K202209000001",
        assetType: "PC",
        typeName: "노트북",
        model: "LG 그램 15",
        manufacturer: "LG",
        dept: "교무실",
        deptCode: "D001",
        status: "정상",
        statusCode: "N",
        user: "김철수",
        userId: "U001",
        purchaseDate: "2022-09-15",
        expireDate: "2027-09-15"
    },

    // A1-2: 수리중 (같은 부서 - 교무실)
    "HP24MON2023050002": {
        serial: "HP24MON2023050002",
        assetType: "모니터",
        typeName: "모니터",
        model: "HP 24인치 FHD",
        manufacturer: "HP",
        dept: "교무실",
        deptCode: "D001",
        status: "수리중",
        statusCode: "R",
        user: "박영희",
        userId: "U002",
        purchaseDate: "2023-05-20",
        expireDate: "2028-05-20",
        repairInfo: {
            requestDate: "2025-01-15",
            reason: "화면 깜빡임",
            vendor: "HP 서비스센터"
        }
    },

    // A1-3: 폐기 (같은 부서 - 교무실)
    "DELLXPS2019120003": {
        serial: "DELLXPS2019120003",
        assetType: "PC",
        typeName: "노트북",
        model: "Dell XPS 13",
        manufacturer: "Dell",
        dept: "교무실",
        deptCode: "D001",
        status: "폐기",
        statusCode: "D",
        user: null,
        userId: null,
        purchaseDate: "2019-12-10",
        expireDate: "2024-12-10",
        disposeInfo: {
            disposeDate: "2024-06-15",
            reason: "사용연한 만료",
            approver: "전산실장"
        }
    },

    // A1-4: 분실 (같은 부서 - 교무실)
    "SAMSUNGTAB2022080004": {
        serial: "SAMSUNGTAB2022080004",
        assetType: "태블릿",
        typeName: "태블릿",
        model: "삼성 Galaxy Tab S8",
        manufacturer: "삼성",
        dept: "교무실",
        deptCode: "D001",
        status: "분실",
        statusCode: "L",
        user: "최지훈",
        userId: "U003",
        purchaseDate: "2022-08-25",
        expireDate: "2027-08-25",
        lostInfo: {
            reportDate: "2024-01-10",
            lastLocation: "본관 3층 회의실",
            reporter: "최지훈"
        }
    },

    // A2-1: 다른 부서 (입학팀 → 교무실 이동)
    "LGGRAM2024010005": {
        serial: "LGGRAM2024010005",
        assetType: "PC",
        typeName: "노트북",
        model: "LG 그램 17",
        manufacturer: "LG",
        dept: "입학팀",           // 현재 위치(교무실)와 다름
        deptCode: "D002",
        status: "정상",
        statusCode: "N",
        user: "이민수",
        userId: "U004",
        purchaseDate: "2024-01-05",
        expireDate: "2029-01-05"
    },

    // A2-2: 다른 부서 + 수리중 (총무팀 → 교무실)
    "HPPRINTER2022030006": {
        serial: "HPPRINTER2022030006",
        assetType: "프린터",
        typeName: "레이저프린터",
        model: "HP LaserJet Pro M404",
        manufacturer: "HP",
        dept: "총무팀",           // 현재 위치(교무실)와 다름
        deptCode: "D003",
        status: "수리중",
        statusCode: "R",
        user: "정수현",
        userId: "U005",
        purchaseDate: "2022-03-18",
        expireDate: "2027-03-18",
        repairInfo: {
            requestDate: "2025-01-20",
            reason: "용지 걸림 반복",
            vendor: "내부 수리"
        }
    },

    // 다중 시리얼 테스트용 - 모니터 1
    "LED2023051001A1": {
        serial: "LED2023051001A1",
        assetType: "모니터",
        typeName: "모니터",
        model: "LG 27인치 4K",
        manufacturer: "LG",
        dept: "교무실",
        deptCode: "D001",
        status: "정상",
        statusCode: "N",
        user: "김철수",
        userId: "U001",
        purchaseDate: "2023-05-10",
        expireDate: "2028-05-10"
    },

    // 다중 시리얼 테스트용 - 모니터 2
    "LED2023051001A2": {
        serial: "LED2023051001A2",
        assetType: "모니터",
        typeName: "모니터",
        model: "LG 27인치 4K",
        manufacturer: "LG",
        dept: "교무실",
        deptCode: "D001",
        status: "정상",
        statusCode: "N",
        user: "김철수",
        userId: "U001",
        purchaseDate: "2023-05-10",
        expireDate: "2028-05-10"
    }
};

// ============================================================
// 납품 예정 데이터 (TB_DELIVERY Mock)
// ============================================================
const MOCK_DELIVERIES = {
    // B1: 납품 대기
    "NEWDELL2025010007": {
        serial: "NEWDELL2025010007",
        assetType: "PC",
        typeName: "데스크톱",
        model: "Dell Optiplex 7090",
        manufacturer: "Dell",
        expectedDate: "2025-01-25",
        vendor: "(주)델테크놀로지",
        poNumber: "PO-2025-0125",
        quantity: 10,
        unitPrice: 1200000
    }
};

// ============================================================
// 부서 데이터 (TB_DEPARTMENT Mock)
// ============================================================
const MOCK_DEPARTMENTS = {
    "D001": { code: "D001", name: "교무실", building: "본관", floor: "1층", parent: null },
    "D002": { code: "D002", name: "입학팀", building: "본관", floor: "2층", parent: null },
    "D003": { code: "D003", name: "총무팀", building: "본관", floor: "1층", parent: null },
    "D004": { code: "D004", name: "전산실", building: "본관", floor: "B1층", parent: null },
    "D005": { code: "D005", name: "학생처", building: "학생회관", floor: "1층", parent: null }
};

// ============================================================
// API 함수 (나중에 실제 API로 교체)
// ============================================================

/**
 * 시리얼로 자산 조회
 * @param {string} serial - 시리얼 번호
 * @returns {Promise<object|null>} 자산 정보 또는 null
 */
async function findAsset(serial) {
    // Mock 모드: 지연 시뮬레이션
    await delay(200);
    return MOCK_ASSETS[serial] || null;

    // 실제 API 모드 (나중에 교체)
    // return await fetch('/api/asset/' + serial).then(r => r.json());
}

/**
 * 시리얼로 납품 데이터 조회
 * @param {string} serial - 시리얼 번호
 * @returns {Promise<object|null>} 납품 정보 또는 null
 */
async function findDelivery(serial) {
    await delay(100);
    return MOCK_DELIVERIES[serial] || null;
}

/**
 * 시리얼 조회 (자산 → 납품 순서로 검색)
 * @param {string} serial - 시리얼 번호
 * @param {string} currentDept - 현재 점검 위치 부서코드
 * @returns {Promise<object>} 조회 결과 + 케이스 판정
 */
async function lookupSerial(serial, currentDept) {
    // 1. 자산 DB 조회
    const asset = await findAsset(serial);
    if (asset) {
        const isSameDept = (asset.deptCode === currentDept);
        return {
            found: true,
            source: 'asset',
            data: asset,
            case: determineCase(asset, isSameDept)
        };
    }

    // 2. 납품 데이터 조회
    const delivery = await findDelivery(serial);
    if (delivery) {
        return {
            found: true,
            source: 'delivery',
            data: delivery,
            case: 'B1'
        };
    }

    // 3. 미등록
    return {
        found: false,
        source: null,
        data: null,
        case: 'C1'
    };
}

/**
 * 케이스 판정 (A1-x, A2-x)
 */
function determineCase(asset, isSameDept) {
    const prefix = isSameDept ? 'A1' : 'A2';

    switch (asset.statusCode) {
        case 'N': return prefix + '-1';  // 정상
        case 'R': return prefix + '-2';  // 수리중
        case 'D': return prefix + '-3';  // 폐기
        case 'L': return prefix + '-4';  // 분실
        default: return prefix + '-1';
    }
}

/**
 * 부서 목록 조회
 */
async function getDepartments() {
    await delay(100);
    return Object.values(MOCK_DEPARTMENTS);
}

/**
 * 지연 함수 (네트워크 시뮬레이션)
 */
function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// ============================================================
// Export (모듈 사용 시)
// ============================================================
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        MOCK_ASSETS,
        MOCK_DELIVERIES,
        MOCK_DEPARTMENTS,
        findAsset,
        findDelivery,
        lookupSerial,
        getDepartments
    };
}
