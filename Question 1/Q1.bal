// Question 1: RESTful APIs- Library and Resource Management System

public type AssetStatus "AVAILABLE"|"LOANED_OUT"|"OCCUPIED"|"UNDER_MAINTENANCE"|"DISPOSED";

// A component of an asset
public type Component record {|
    string compId;
    string name;
    string description;
|};

// A servicing schedule entry
public type Schedule record {|
    string scheduleId;
    string 'type;          
    string dueDate;       
    string description;
|};

// A single task inside a work order
public type Task record {|
    string taskId;
    string description;
    boolean completed = false;
|};

// A work order raised against a faulty resource
public type WorkOrder record {|
    string orderId;
    string status;       
    string description;
    Task[] tasks;
|};


public type Asset record {|
    readonly string assetTag;      
    string name;
    string description;
    string institution;
    string site;
    AssetStatus status;
    string dateAcquired;           
    Component[] components = [];
    Schedule[] schedules = [];
    WorkOrder[] workOrders = [];
|};


public map<Asset> assetStore = {};

public function addAsset(Asset newAsset) returns error? {
    if assetStore.hasKey(newAsset.assetTag) {
        return error("Duplicate assetTag: '" + newAsset.assetTag +
                      "' already exists. assetTag must be unique.");
    }
    assetStore[newAsset.assetTag] = newAsset;
}

public function sampleData() {

    Asset printer = {
        assetTag: "NUST-LIB-PRI-001",
        name: "HP Deskjet Printer",
        description: "Standard office printer.",
        institution: "Namibia University of Science and Technology",
        site: "Main Campus -Library - Periodicals Section",
        status: "AVAILABLE",
        dateAcquired: "2024-03-10",
        components: [
            {
                compId: "C101",
                name: "Ink Cartridge",
                description: "Standard ink cartridge for HP Deskjet printers."
            }
        ],
        schedules: [
            {
                scheduleId: "SCH-882",
                'type: "MAINTENANCE",
                dueDate: "2026-09-01",
                description: "Quarterly maintenance."
            }
        ],
        workOrders: [
            {
                orderId: "WO-554",
                status: "OPEN",
                description: "Printer not responding to print commands.",
                tasks: [
                    { taskId: "T1", description: "Check ink levels." }
                ]
            }
        ]
    };

    Asset laptop = {
        assetTag: "NUST-LAP-014",
        name: "Dell Latitude 5440",
        description: "Staff loan laptop, i7/16GB/512GB SSD.",
        institution: "Namibia University of Science and Technology",
        site: "Main Campus - Library - Book Loan Section",
        status: "LOANED_OUT",
        dateAcquired: "2023-11-20"
    };

    Asset meetingRoom = {
        assetTag: "UNAM-RM-BB2-002",
        name: "Boardroom B2",
        description: "12-seater meeting room with projector and video conferencing.",
        institution: "University of Namibia",
        site: "Main Campus - Block B",
        status: "OCCUPIED",
        dateAcquired: "2021-06-01",
        schedules: [
            {
                scheduleId: "SCH-101",
                'type: "BOOKING",
                dueDate: "2026-09-11",
                description: "Faculty meeting, 09:00 - 11:00."
            }
        ]
    };

    Asset labPC = {
        assetTag: "IUM-LAB-PC-077",
        name: "HP EliteDesk Lab Workstation",
        description: "Computer lab workstation, unit 077.",
        institution: "International University of Management",
        site: "Main Campus - Computer Lab 3",
        status: "UNDER_MAINTENANCE",
        dateAcquired: "2022-02-15",
        schedules: [
            {
                scheduleId: "SCH-205",
                'type: "MAINTENANCE",
                dueDate: "2026-08-20",  
                description: "Replace faulty RAM module."
            }
        ]
    };

    Asset oldServer = {
        assetTag: "NUST-SRV-009",
        name: "Legacy File Server",
        description: "Decommissioned department file server.",
        institution: "Namibia University of Science and Technology",
        site: "Main Campus - Server Room",
        status: "DISPOSED",
        dateAcquired: "2015-01-10"
    };

    error? r1 = addAsset(printer);
    error? r2 = addAsset(laptop);
    error? r3 = addAsset(meetingRoom);
    error? r4 = addAsset(labPC);
    error? r5 = addAsset(oldServer);
}
