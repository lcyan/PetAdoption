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

CREATE TABLE IF NOT EXISTS t_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    a_id VARCHAR(255),
    admin_action VARCHAR(255),
    object VARCHAR(255),
    create_time VARCHAR(255),
    url VARCHAR(500)
);

CREATE TABLE IF NOT EXISTS t_userlog (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(255),
    user_action VARCHAR(255),
    pet_id VARCHAR(255),
    create_time VARCHAR(255),
    url VARCHAR(500)
);

INSERT INTO t_admin (admin_id, admin_account, admin_password, admin_name, admin_age, admin_sex, admin_telephone, admin_email)
VALUES ('1', 'admin', 'admin', '管理员', '20', '男', '13800138000', 'admin@pet.com');

-- 初始化宠物数据
INSERT INTO t_pet (pet_id, pet_name, pet_sex, pet_sub, pet_type, pet_bir, pet_detail, pet_pic, pet_state) VALUES
('1', '小白', '公', '金毛', '狗狗', '2023-01-15', '性格温顺，喜欢和人亲近，适合家庭饲养', 'https://images.unsplash.com/photo-1552053831-71594a27632d?w=400', '未领养');

INSERT INTO t_pet (pet_id, pet_name, pet_sex, pet_sub, pet_type, pet_bir, pet_detail, pet_pic, pet_state) VALUES
('2', '咪咪', '母', '英短', '猫咪', '2023-03-20', '活泼可爱，喜欢玩耍，已接种疫苗', 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400', '未领养');

INSERT INTO t_pet (pet_id, pet_name, pet_sex, pet_sub, pet_type, pet_bir, pet_detail, pet_pic, pet_state) VALUES
('3', '旺财', '公', '泰迪', '狗狗', '2022-11-08', '聪明伶俐，会握手坐下等基本指令', 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=400', '未领养');
