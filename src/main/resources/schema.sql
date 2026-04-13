CREATE TABLE IF NOT EXISTS t_admin (
    admin_id VARCHAR(255) PRIMARY KEY,
    admin_account VARCHAR(255),
    admin_password VARCHAR(255),
    admin_name VARCHAR(255),
    admin_age VARCHAR(255),
    admin_sex VARCHAR(255),
    admin_telephone VARCHAR(255),
    admin_email VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS t_pet (
    pet_id VARCHAR(255) PRIMARY KEY,
    pet_name VARCHAR(255),
    pet_sex VARCHAR(255),
    pet_sub VARCHAR(255),
    pet_type VARCHAR(255),
    pet_bir VARCHAR(255),
    pet_detail VARCHAR(1000),
    pet_pic VARCHAR(255),
    pet_state VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS t_user (
    user_id VARCHAR(255) PRIMARY KEY,
    user_account VARCHAR(255),
    user_password VARCHAR(255),
    user_name VARCHAR(255),
    user_age VARCHAR(255),
    user_sex VARCHAR(255),
    user_telephone VARCHAR(255),
    user_email VARCHAR(255),
    user_address VARCHAR(255),
    user_state VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS t_apply (
    apply_id VARCHAR(255) PRIMARY KEY,
    apply_user_name VARCHAR(255),
    apply_pet_name VARCHAR(255),
    apply_user_sex VARCHAR(255),
    apply_user_address VARCHAR(255),
    apply_user_telephone VARCHAR(255),
    apply_user_state VARCHAR(255),
    apply_time VARCHAR(255),
    apply_state VARCHAR(255),
    apply_user_id VARCHAR(255),
    apply_pet_id VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS t_file (
    file_id VARCHAR(255) PRIMARY KEY,
    file_name VARCHAR(255),
    file_url VARCHAR(500),
    file_time VARCHAR(255),
    file_uid VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS t_sys_log (
    log_id VARCHAR(255) PRIMARY KEY,
    log_time VARCHAR(255),
    log_username VARCHAR(255),
    log_operation VARCHAR(255),
    log_method VARCHAR(500),
    log_params VARCHAR(1000),
    log_ip VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS t_user_log (
    log_id VARCHAR(255) PRIMARY KEY,
    log_time VARCHAR(255),
    log_username VARCHAR(255),
    log_operation VARCHAR(255),
    log_method VARCHAR(500),
    log_params VARCHAR(1000),
    log_ip VARCHAR(255)
);

INSERT INTO t_admin (admin_id, admin_account, admin_password, admin_name, admin_age, admin_sex, admin_telephone, admin_email) 
VALUES ('1', 'admin', 'admin', '管理员', '20', '男', '13800138000', 'admin@pet.com');

INSERT INTO t_pet (pet_id, pet_name, pet_sex, pet_sub, pet_type, pet_bir, pet_detail, pet_pic, pet_state) 
VALUES ('pet001', '小黄', '公', '金毛', '狗', '2020-05-15', '活泼可爱的金毛犬，非常适合家庭饲养', '/img/slider/1.jpg', '未领养');

INSERT INTO t_pet (pet_id, pet_name, pet_sex, pet_sub, pet_type, pet_bir, pet_detail, pet_pic, pet_state) 
VALUES ('pet002', '小花', '母', '波斯猫', '猫', '2021-03-20', '温顺的波斯猫，喜欢安静的环境', '/img/slider/2.jpg', '未领养');

INSERT INTO t_pet (pet_id, pet_name, pet_sex, pet_sub, pet_type, pet_bir, pet_detail, pet_pic, pet_state) 
VALUES ('pet003', '小黑', '公', '拉布拉多', '狗', '2019-08-10', '忠诚可靠的拉布拉多，训练有素', '/img/slider/3.jpg', '未领养');
