create table backlog_task_date_table
(
    unique_project_id                         varchar(20) not null comment 'プロジェクトID＋サブプロジェクトID'
        primary key,
    inspection_preparation_start_date         varchar(20) null comment '検査準備開始日（設計計画書の検査実施要領書出図日）',
    inspection_preparation_end_date           varchar(20) null comment '検査準備終了日（検査実施要領書の入検日）',
    inspection_start_date                     varchar(20) null comment '検査開始日（設計計画書の入検日）',
    inspection_end_date                       varchar(20) null comment '検査終了日（設計計画書のDVa完了日）',
    inspection_meeting_preparation_start_date varchar(20) null comment '立会検査準備開始日（設計計画書のDVa）',
    inspection_meeting_preparation_end_date   varchar(20) null comment '立会検査準備終了日（設計計画書の立会日－１日）',
    inspection_meeting_start_date             varchar(20) null comment '立会検査開始日（設計計画書の立会日）',
    inspection_meeting_end_date               varchar(20) null comment '立会検査終了日（設計計画書の出荷日）',
    shipping_preparation_start_date           varchar(20) null comment '出荷準備開始日（設計計画書のDVaまたは立会日～出荷ー１まで）',
    shipping_preparation_end_date             varchar(20) null comment '出荷準備終了日（設計計画書の出荷日）',
    shipping_start_date                       varchar(20) null comment '出荷開始日（設計計画書の出荷日）',
    shipping_end_date                         varchar(20) null comment '出荷終了日（設計計画書の出荷日）'
)
    comment '各工程情報を保存するテーブル';

create table backlog_task_ids_table
(
    id                int auto_increment
        primary key,
    unique_project_id varchar(100) null,
    summary           varchar(100) null,
    issue_id          int          null,
    parent            tinyint(1)   null,
    backlog_pj_id     int          not null
);

create table backlog_users_table
(
    id            int          not null
        primary key,
    userId        varchar(50)  not null,
    name          varchar(100) not null,
    roleType      int          null,
    lang          varchar(10)  null,
    mailAddress   varchar(100) null,
    lastLoginTime datetime     null,
    constraint user_id
        unique (userId)
);

create table blue_prints_table
(
    id                   int auto_increment
        primary key,
    unique_project_id    varchar(20)          null comment 'ユニークプロジェクトID',
    blue_print_file_name varchar(100)         null comment '図面ファイル名',
    blue_print_kind_id   int                  null comment '図面種別ID',
    blue_print_dl_link   varchar(255)         null comment '図面ダウンロードリンク',
    downloaded           tinyint(1) default 0 null comment 'ダウンロード状況'
)
    comment '出図済み図面一覧';

create table blueprint_kind_table
(
    blue_print_kind_id   int      not null comment '図面種別ID'
        primary key,
    blue_print_kind_name char(50) null comment '図面種別名'
)
    comment '図面種別定義テーブル';

create table blue_print_alert_history_table
(
    id                 int auto_increment
        primary key,
    unique_project_id  varchar(20) not null comment 'ユニークプロジェクトID（プロジェクトID＋サブプロジェクトID）',
    blue_print_kind_id int         not null comment '図面種別ID',
    status             tinyint(1)  not null comment '出図状況',
    constraint blue_print_alert_history_table_blue_print_fk
        foreign key (blue_print_kind_id) references blueprint_kind_table (blue_print_kind_id)
)
    comment '各案件ごとの出図図面一覧';

create table blue_prints_alert_setting_table
(
    id                 int auto_increment
        primary key,
    subproject_type_id int not null comment 'サブプロジェクト種別',
    blue_print_kind_id int not null comment '図面種別ID',
    process_kind_id    int not null comment '工程ID',
    alert_offset_date  int not null comment 'アラートアクティベートのオフセット日数',
    constraint blue_prints_kind_id_fk
        foreign key (blue_print_kind_id) references blueprint_kind_table (blue_print_kind_id)
)
    comment '図面出図におけるアラート出力オフセット設定';

create table design_plan_table
(
    unique_project_id         varchar(20) not null comment 'プロジェクトID＋サブプロジェクトID'
        primary key,
    components_list_date      varchar(20) null comment '構成品目表出図日',
    drawing_release_date      varchar(20) null comment '図面出図日',
    inspection_guideline_date varchar(20) null comment '検査実施要領書出図日',
    dr_date                   varchar(20) null comment 'DR（打ち合わせ）予定日',
    dve_date                  varchar(20) null,
    incoming_inspection_date  varchar(20) null comment '入検日',
    inspection_meeting_date   varchar(20) null comment '立会日',
    dva_date                  varchar(20) null comment 'DVa予定日',
    ship_date                 varchar(20) null comment '出荷予定日',
    completion_documents_date varchar(20) null comment '完成図書出図予定日',
    years                     varchar(20) not null comment '年度'
)
    comment '設計計画書情報テーブル';

create table device_used_history_table
(
    id                int auto_increment
        primary key,
    unique_project_id char(20) null comment 'プロジェクトID＋サブプロジェクトID',
    device_id         char(10) null comment '測定器ID',
    using_start_date  datetime null comment '利用開始日',
    using_end_date    datetime null comment '利用終了日'
);

create table drawing_status_table
(
    unique_project_id  char(20) not null
        primary key,
    blue_print_kind_id char(20) null comment '図面種別ID',
    status_id          int      null
)
    comment '図面出図状態テーブル';

create table dva_history_table
(
    unique_project_id varchar(50)  not null
        primary key,
    sub_project_name  varchar(100) null comment '件名',
    client_name       varchar(100) null comment '客先名',
    status            varchar(20)  null comment '状態',
    file_path         varchar(999) not null comment 'ファイルパス',
    control_number    varchar(20)  null comment '管理番号',
    completion_id     varchar(20)  null comment '整理番号'
);

create table external_users_table
(
    jrc_user_code    varchar(10)  not null
        primary key,
    jrc_user_name    varchar(50)  not null,
    jrc_mail_address varchar(255) null,
    jrc_group_id     int          not null,
    password         varchar(255) not null,
    system_admin     tinyint(1)   not null,
    admin            tinyint(1)   not null,
    standard         tinyint(1)   not null,
    guest            tinyint(1)   not null,
    created_at       datetime     not null,
    updated_at       datetime     not null
);

create table group_kind_table
(
    jrc_group_id   int      not null comment 'グループID'
        primary key,
    jrc_group_name char(50) null comment 'グループ名',
    jrc_group_code char(20) null comment 'グループコード'
)
    comment 'グループ種別定義テーブル';

create table ifs_components_table
(
    other_demand_sequence           double       not null comment 'その他需要連番'
        primary key,
    project_id                      varchar(50)  null comment 'プロジェクトID',
    activity_sequence               varchar(50)  null comment 'アクティビティ番号',
    site                            varchar(50)  null,
    digit_number                    varchar(50)  null comment '桁番号',
    item_name                       varchar(255) null comment '品名',
    standard_planned_item           varchar(50)  null,
    required_quantity               varchar(50)  null comment '要求数量',
    requested_quantity              varchar(50)  null comment '要求済み数量',
    allocated_quantity              varchar(50)  null,
    received_quantity               varchar(50)  null comment '入庫数量',
    shipped_quantity                varchar(50)  null comment '出庫数量',
    allocated_at_receipt            varchar(50)  null,
    receipt_date                    varchar(50)  null,
    shipment_date                   varchar(50)  null comment '出荷日',
    allocatable                     varchar(50)  null,
    desired_delivery_date           varchar(50)  null,
    arrangement_date                varchar(50)  null,
    shipping_flag                   varchar(50)  null comment '出荷フラグ',
    manufacturing_number            varchar(50)  null comment '製造番号',
    supply_option                   varchar(50)  null comment '手配区分（購買・在庫等）',
    shipment_info_id                varchar(50)  null comment '出荷情報ID',
    shipping_date                   varchar(50)  null comment '出荷日',
    shape_name                      varchar(50)  null comment '型名',
    assembly_sign                   varchar(50)  null comment '組込サイン（桁番号に紐づく）',
    power_source                    varchar(50)  null,
    power_source_name               varchar(50)  null,
    instruction_sign                varchar(50)  null,
    destination                     varchar(50)  null,
    shipping_item_list_sign         varchar(50)  null comment '出荷リストサイン',
    prior_shipment_sign             varchar(50)  null comment '出荷サイン',
    instruction_notes               varchar(999) null comment '手配についての備考',
    shipping_request_quantity       varchar(50)  null comment '出荷要求数量',
    registration_date_time          varchar(50)  null,
    registrant                      varchar(50)  null,
    update_date_time                varchar(50)  null comment '更新日時',
    updater                         varchar(50)  null comment '更新者',
    shipping_base                   varchar(50)  null,
    withdrawal_instruction_date     varchar(50)  null comment '払出完了日',
    withdrawn_instruction_amount    varchar(50)  null comment '払出数',
    withdrawal_destination          varchar(50)  null comment '払出先',
    withdrawal_instruction_reg_date varchar(50)  null comment '払出（入検）要求日',
    sub_project_id                  varchar(50)  null comment 'サブプロジェクトID',
    activity_name                   varchar(255) null comment '装置区分',
    parent_sub_project_id           varchar(50)  null
);

create table ifs_projects_table
(
    unique_project_id       varchar(20)  not null comment 'ユニークプロジェクトID',
    project_id              varchar(20)  not null comment 'プロジェクトID',
    sub_project_id          varchar(20)  null comment 'サブプロジェクトID',
    sub_project_name        varchar(255) null comment '社内件名',
    department              varchar(50)  null comment '部門',
    parent_sub_project_id   varchar(20)  null comment '親サブプロジェクトID（SPJとか）',
    variety                 varchar(50)  null comment 'サブプロジェクト種別',
    sub_project_amount      varchar(50)  null comment 'サブプロジェクト金額',
    sub_project_cost        varchar(50)  null comment 'サブプロジェクトコスト',
    completion_request_date varchar(50)  null comment '完了要求日',
    completion_request      varchar(50)  null comment '完了要求',
    status                  varchar(20)  null comment '完了状態',
    variety_name            varchar(50)  null comment 'サブプロジェクト種別',
    project_name            varchar(50)  null comment 'プロジェクト名',
    accounting_completed    varchar(50)  null comment '完了状態',
    completion_date         varchar(50)  null comment '完了日',
    initial_completion_date varchar(50)  null comment '初回完了日時',
    primary key (unique_project_id, project_id)
)
    comment 'プロジェクト一覧テーブル';

create table information_equipment_assign_table
(
    information_device_id varchar(30)                        not null comment '識別ID',
    serial_number         varchar(50)                        null comment '製造番号',
    device_type_name      varchar(40)                        null comment '機器型名',
    device_name           varchar(50)                        null comment '機器名称',
    jrc_user_name         varchar(50)                        null comment '氏名',
    jrc_user_code         varchar(50)                        null comment '個人コード',
    department            varchar(50)                        null comment '事業部名',
    department2           varchar(50)                        null comment '部門名',
    jrc_group_id          int                                null comment 'グループID',
    place                 varchar(50)                        null comment '利用場所',
    building_number       varchar(50)                        null comment '建物番号',
    flore                 varchar(50)                        null comment 'フロア',
    device_variety_id     int                                null comment '機器種別ID',
    ip_address            varchar(50)                        null comment 'IPアドレス',
    using_for             varchar(50)                        null comment '利用用途',
    `order`               varchar(50)                        null comment '支払いオーダ',
    price_par_month       varchar(50)                        null comment '月額',
    check_date            varchar(50)                        null comment '棚卸日',
    update_date           datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '情報更新日時'
);

create table jrc_users_table
(
    jrc_user_code    char(10) not null comment '個人コード'
        primary key,
    jrc_user_name    char(50) null comment 'ユーザー名',
    jrc_mail_address char(50) null comment 'メールアドレス',
    jrc_group_id     int      null comment 'グループID',
    constraint jrc_users_table_group_kind_table_jrc_group_id_fk
        foreign key (jrc_group_id) references group_kind_table (jrc_group_id)
);

create table measuring_device_kind_table
(
    device_id           char(10)                                                  not null comment '計測器管理番号'
        primary key,
    device_name         varchar(100)                                              null comment '計測器名称',
    device_type_name    varchar(100)                                              null comment '計測器型名',
    device_maker        varchar(100)                                              null comment '計測器メーカ',
    proofreading_date   date                                                      null comment '校正年月日',
    expiration_date     date                                                      null comment '校正有効期限',
    external_rental     tinyint(1)                                                null comment '0=社内レンタル、1=外部レンタル',
    lending_destination varchar(100)                                              null comment '貸出先',
    remarks             text                                                      null comment '備考',
    lending             tinyint(1) default (ifnull(`lending_destination`, false)) null comment '1=貸出中',
    update_date         datetime   default (now())                                null on update CURRENT_TIMESTAMP
)
    comment '計測器一覧テーブル';

create table device_assign_table
(
    jrc_user_code char(10)    not null comment '個人コード'
        primary key,
    device_id     varchar(10) null comment '測定器ID',
    constraint device_assign_table_measuring_device_kind_table_device_id_fk
        foreign key (device_id) references measuring_device_kind_table (device_id)
)
    comment '機器割り当て用テーブル';

create table nulab_accounts_table
(
    id        int auto_increment
        primary key,
    user_id   varchar(50)  not null,
    nulab_id  varchar(100) null,
    name      varchar(100) null,
    unique_id varchar(100) null,
    constraint nulab_accounts_table_ibfk_1
        foreign key (user_id) references backlog_users_table (userId)
            on delete cascade
);

create index user_id
    on nulab_accounts_table (user_id);

create table pending_table
(
    id            int auto_increment
        primary key,
    ask_date      datetime     null comment '質問日時',
    asker         varchar(100) null comment '質問者',
    feedback_text text         null comment '要望内容',
    responder     varchar(100) null comment '回答者',
    response_text text         null comment '回答内容',
    response_date datetime     null comment '回答日時'
);

create table process_kind_table
(
    process_kind_id   int      not null comment '工程区分ID'
        primary key,
    process_kind_name char(50) null comment '工程区分名'
)
    comment '工程区分定義テーブル';

create table production_process_table
(
    unique_project_id        char(20) not null
        primary key,
    process_kind_id          int      null,
    start_date               datetime null,
    end_date                 datetime null,
    plan_man_hours           int      null,
    actual_man_hours         int      null,
    incoming_inspection_date datetime null,
    shipment_date            datetime null,
    inspection_meeting_date  datetime null
);

create table project_assign_table
(
    id                int auto_increment
        primary key,
    unique_project_id char(20)   null comment 'プロジェクトID＋サブプロジェクトID',
    jrc_user_code     char(20)   null comment '個人コード',
    inspection_ready  tinyint(1) null comment '検査可能判定'
);

create table project_full_merged_table_work
(
    unique_project_id                         varchar(20)    null comment 'ユニークプロジェクトID',
    project_id                                longtext       not null,
    sub_project_id                            longtext       null,
    sub_project_name                          longtext       null,
    department                                longtext       null,
    parent_sub_project_id                     longtext       null,
    variety                                   longtext       null,
    sub_project_amount                        longtext       null,
    sub_project_cost                          longtext       null,
    completion_request_date                   longtext       null,
    completion_request                        longtext       null,
    status                                    longtext       null,
    variety_name                              longtext       null,
    project_name                              longtext       null,
    accounting_completed                      longtext       null,
    completion_date                           longtext       null,
    initial_completion_date                   longtext       null,
    inspection_preparation_start_date         longtext       null,
    inspection_preparation_end_date           longtext       null,
    inspection_start_date                     longtext       null,
    inspection_end_date                       longtext       null,
    inspection_meeting_preparation_start_date longtext       null,
    inspection_meeting_preparation_end_date   longtext       null,
    inspection_meeting_start_date             longtext       null,
    inspection_meeting_end_date               longtext       null,
    shipping_preparation_start_date           longtext       null,
    shipping_preparation_end_date             longtext       null,
    shipping_start_date                       longtext       null,
    shipping_end_date                         longtext       null,
    client_name                               longtext       null,
    contract_deadline                         longtext       null,
    shipping_approval_date                    longtext       null,
    progress                                  longtext       null,
    area_used                                 longtext       null,
    deployment_location                       longtext       null,
    business_trip_start_date                  longtext       null,
    business_trip_end_date                    longtext       null,
    technical_manager                         longtext       null,
    admin_manager                             longtext       null,
    person_in_charge                          longtext       null,
    worker                                    longtext       null,
    support_staff                             longtext       null,
    case_name                                 longtext       null,
    man_hours                                 longtext       null,
    used_man_hours                            longtext       null,
    comment                                   longtext       null,
    components_list_date                      longtext       null,
    drawing_release_date                      longtext       null,
    inspection_guideline_date                 longtext       null,
    dr_date                                   longtext       null,
    dve_date                                  longtext       null,
    incoming_inspection_date                  longtext       null,
    inspection_meeting_date                   longtext       null,
    dva_date                                  longtext       null,
    ship_date                                 longtext       null,
    completion_documents_date                 longtext       null,
    years                                     longtext       null,
    jrc_user_code                             longtext       null,
    inspection_ready                          longtext       null,
    complete                                  longtext       null,
    se_comment                                longtext       null,
    ig_comment                                longtext       null,
    partial_ship_date_1                       longtext       null,
    partial_ship_date_2                       longtext       null,
    partial_ship_date_3                       longtext       null,
    partial_ship_date_4                       longtext       null,
    partial_ship_date_5                       longtext       null,
    partial_ship_date_6                       longtext       null,
    partial_ship_date_7                       longtext       null,
    partial_ship_date_8                       longtext       null,
    partial_ship_date_9                       longtext       null,
    responsible                               varchar(50)    null,
    sum_man_hours                             decimal(47, 4) null
);

create table project_full_merged_tmp
(
    unique_project_id                         varchar(20)    null comment 'ユニークプロジェクトID',
    project_id                                longtext       not null,
    sub_project_id                            longtext       null,
    sub_project_name                          longtext       null,
    department                                longtext       null,
    parent_sub_project_id                     longtext       null,
    variety                                   longtext       null,
    sub_project_amount                        longtext       null,
    sub_project_cost                          longtext       null,
    completion_request_date                   longtext       null,
    completion_request                        longtext       null,
    status                                    longtext       null,
    variety_name                              longtext       null,
    project_name                              longtext       null,
    accounting_completed                      longtext       null,
    completion_date                           longtext       null,
    initial_completion_date                   longtext       null,
    inspection_preparation_start_date         longtext       null,
    inspection_preparation_end_date           longtext       null,
    inspection_start_date                     longtext       null,
    inspection_end_date                       longtext       null,
    inspection_meeting_preparation_start_date longtext       null,
    inspection_meeting_preparation_end_date   longtext       null,
    inspection_meeting_start_date             longtext       null,
    inspection_meeting_end_date               longtext       null,
    shipping_preparation_start_date           longtext       null,
    shipping_preparation_end_date             longtext       null,
    shipping_start_date                       longtext       null,
    shipping_end_date                         longtext       null,
    client_name                               longtext       null,
    contract_deadline                         longtext       null,
    shipping_approval_date                    longtext       null,
    progress                                  longtext       null,
    area_used                                 longtext       null,
    deployment_location                       longtext       null,
    business_trip_start_date                  longtext       null,
    business_trip_end_date                    longtext       null,
    technical_manager                         longtext       null,
    admin_manager                             longtext       null,
    person_in_charge                          longtext       null,
    worker                                    longtext       null,
    support_staff                             longtext       null,
    case_name                                 longtext       null,
    man_hours                                 longtext       null,
    used_man_hours                            longtext       null,
    comment                                   longtext       null,
    components_list_date                      longtext       null,
    drawing_release_date                      longtext       null,
    inspection_guideline_date                 longtext       null,
    dr_date                                   longtext       null,
    dve_date                                  longtext       null,
    incoming_inspection_date                  longtext       null,
    inspection_meeting_date                   longtext       null,
    dva_date                                  longtext       null,
    ship_date                                 longtext       null,
    completion_documents_date                 longtext       null,
    years                                     longtext       null,
    jrc_user_code                             longtext       null,
    inspection_ready                          longtext       null,
    complete                                  longtext       null,
    se_comment                                longtext       null,
    ig_comment                                longtext       null,
    partial_ship_date_1                       longtext       null,
    partial_ship_date_2                       longtext       null,
    partial_ship_date_3                       longtext       null,
    partial_ship_date_4                       longtext       null,
    partial_ship_date_5                       longtext       null,
    partial_ship_date_6                       longtext       null,
    partial_ship_date_7                       longtext       null,
    partial_ship_date_8                       longtext       null,
    partial_ship_date_9                       longtext       null,
    responsible                               varchar(50)    null,
    sum_man_hours                             decimal(47, 4) null
);

create table reference_number_table
(
    id                int auto_increment
        primary key,
    unique_project_id varchar(20)              null,
    reference_number  varchar(50)              null,
    about_text        varchar(255)             null,
    project_name      varchar(255)             null,
    add_date          datetime default (now()) null on update CURRENT_TIMESTAMP,
    jrc_user_name     varchar(20)              null,
    jrc_user_code     varchar(20)              null
)
    comment '管理番号・整理番号テーブル';

create table required_drawing_types_table
(
    id                   int auto_increment
        primary key,
    sub_project_type     varchar(10) null comment 'サブプロジェクト種別',
    required_drawing_ids varchar(30) null comment '図面種別ID'
)
    comment '各サブプロジェクト種別ごとに必須な図面種別設定テーブル';

create table shipment_authorization_history_table
(
    id                int auto_increment
        primary key,
    unique_project_id varchar(20)  null,
    filename          varchar(200) null,
    number_of_files   int          null,
    revision          varchar(10)  null,
    added_date        datetime     null,
    comment           text         null
)
    comment '出荷承認依頼履歴テーブル';

create table status_kind_table
(
    status_id   int      not null comment '汎用ステータスID'
        primary key,
    status_name char(50) null comment 'ステータス名称'
)
    comment '汎用状態定義テーブル';

create table system_processes_table
(
    process_id           int auto_increment comment 'プロセスID'
        primary key,
    process_ip_address   varchar(50) null comment '起動用IPアドレス',
    process_port_number  varchar(50) null comment '起動用ポート番号',
    process_name         varchar(50) null comment 'プロセス名称',
    process_alive_status tinyint(1)  null comment 'プロセス生存状態'
)
    comment '各マイクロサービスの起動情報設定テーブル';

create table update_history
(
    id             int auto_increment
        primary key,
    process_id     int         not null comment 'プロセスID',
    process_name   varchar(20) null comment 'プロセス名称',
    update_date    datetime    null comment '更新日時',
    update_comment text        null comment '更新コメント'
)
    comment 'システム全体の変更履歴情報（公開用）';

create table user_auth_level_table
(
    jrc_user_code varchar(10) not null comment '個人コード'
        primary key,
    system_admin  tinyint(1)  not null comment 'システム管理ユーザー',
    admin         tinyint(1)  null comment '管理ユーザー',
    standard      tinyint(1)  not null comment '標準ユーザー',
    guest         tinyint(1)  not null comment 'ゲストユーザー'
)
    comment 'ユーザー権限設定テーブル';

create table work_item_kind_table
(
    id          int auto_increment comment '自動生成の一意のID'
        primary key,
    item_number varchar(10) not null comment '作業種別番号',
    item_name   varchar(50) not null comment '作業種別名'
)
    comment '作業種別マスタ';

create table work_time_record_table
(
    id                      int auto_increment
        primary key,
    unique_project_id       varchar(20) not null comment 'プロジェクトID＋サブプロジェクトID',
    jrc_user_code           varchar(10) not null comment 'ユーザーコード',
    process_kind_id         int         not null comment '検査準備、検査、立会検査準備、立会、出荷準備、出荷を表すID',
    start_date              datetime    null comment '開始日時',
    end_date                datetime    null comment '終了日時',
    item_number             varchar(10) null comment '工程種別ID（work_item_kind_tableに準ずる）',
    one_time_bind_user_code varchar(20) null comment '担当者以外で一時的に作業を行った人員のユーザーコード'
)
    comment '作業時間記録用テーブル';

