CREATE TABLE IF NOT EXISTS t_admin (
    adminId VARCHAR(255) PRIMARY KEY,
    adminAccount VARCHAR(255),
    adminPassword VARCHAR(255),
    adminName VARCHAR(255),
    adminAge VARCHAR(255),
    adminSex VARCHAR(255),
    adminTelephone VARCHAR(255),
    adminEmail VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS t_pet (
    petId VARCHAR(255) PRIMARY KEY,
    petName VARCHAR(255),
    petSex VARCHAR(255),
    petSub VARCHAR(255),
    petType VARCHAR(255),
    petBir VARCHAR(255),
    petDetail VARCHAR(1000),
    petPic VARCHAR(255),
    petState VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS t_user (
    userId VARCHAR(255) PRIMARY KEY,
    userAccount VARCHAR(255),
    userPassword VARCHAR(255),
    userName VARCHAR(255),
    userAge VARCHAR(255),
    userSex VARCHAR(255),
    userTelephone VARCHAR(255),
    userEmail VARCHAR(255),
    userAddress VARCHAR(255),
    userState VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS t_apply (
    applyId VARCHAR(255) PRIMARY KEY,
    applyUserName VARCHAR(255),
    applyPetName VARCHAR(255),
    applyUserSex VARCHAR(255),
    applyUserAddress VARCHAR(255),
    applyUserTelephone VARCHAR(255),
    applyUserState VARCHAR(255),
    applyTime VARCHAR(255),
    applyState VARCHAR(255),
    applyUserId VARCHAR(255),
    applyPetId VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS t_file (
    fileId VARCHAR(255) PRIMARY KEY,
    fileName VARCHAR(255),
    fileUrl VARCHAR(500),
    fileTime VARCHAR(255),
    fileUid VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS t_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    aId VARCHAR(255),
    adminAction VARCHAR(255),
    object VARCHAR(255),
    createTime VARCHAR(255),
    url VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS t_userlog (
    logId VARCHAR(255) PRIMARY KEY,
    userId VARCHAR(255),
    userAction VARCHAR(255),
    petId VARCHAR(255),
    createTime VARCHAR(255),
    url VARCHAR(255)
);

INSERT INTO t_admin (adminId, adminAccount, adminPassword, adminName, adminAge, adminSex, adminTelephone, adminEmail) 
VALUES ('1', 'admin', 'admin', '管理员', '20', '男', '13800138000', 'admin@pet.com');
