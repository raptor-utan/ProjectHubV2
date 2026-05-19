-- we don't know how to generate root <with-no-name> (class Root) :(

grant select on performance_schema.* to 'mysql.session'@localhost;

grant trigger on sys.* to 'mysql.sys'@localhost;

grant alter, alter routine, create, create routine, create tablespace, create temporary tables, create user, create view, delete, drop, event, execute, file, index, insert, lock tables, process, references, reload, replication client, replication slave, select, show databases, show view, shutdown, super, trigger, update, grant option on *.* to dbuser;

grant audit_abort_exempt, firewall_exempt, select, system_user on *.* to 'mysql.infoschema'@localhost;

grant audit_abort_exempt, authentication_policy_admin, backup_admin, clone_admin, connection_admin, firewall_exempt, persist_ro_variables_admin, session_variables_admin, shutdown, super, system_user, system_variables_admin on *.* to 'mysql.session'@localhost;

grant audit_abort_exempt, firewall_exempt, system_user on *.* to 'mysql.sys'@localhost;

grant alter, alter routine, application_password_admin, audit_abort_exempt, audit_admin, authentication_policy_admin, backup_admin, binlog_admin, binlog_encryption_admin, clone_admin, connection_admin, create, create role, create routine, create tablespace, create temporary tables, create user, create view, delete, drop, drop role, encryption_key_admin, event, execute, file, firewall_exempt, flush_optimizer_costs, flush_status, flush_tables, flush_user_resources, group_replication_admin, group_replication_stream, index, innodb_redo_log_archive, innodb_redo_log_enable, insert, lock tables, passwordless_user_admin, persist_ro_variables_admin, process, references, reload, replication client, replication slave, replication_applier, replication_slave_admin, resource_group_admin, resource_group_user, role_admin, select, sensitive_variables_observer, service_connection_admin, session_variables_admin, set_user_id, show databases, show view, show_routine, shutdown, super, system_user, system_variables_admin, table_encryption_admin, telemetry_log_admin, trigger, update, xa_recover_admin, grant option on *.* to root@localhost;

create table project_hub.active_sessions
(
    session_id    text null,
    user_id       text null,
    last_activity text null
);

create table plango.active_sessions
(
    session_id    varchar(255)                        not null
        primary key,
    user_id       varchar(255)                        not null,
    last_activity timestamp default CURRENT_TIMESTAMP null
);

create table login_info.active_users_table
(
    jrc_user_code      varchar(10)                  not null comment '個人コード'
        primary key,
    login_time         datetime default (curdate()) null comment 'ログイン日時（自動ログアウト判定処理用）',
    identification_key varchar(40)                  null comment '識別キー（JWTトークンの代わり）'
);

create table plango.affiliation_categories
(
    id            int unsigned auto_increment
        primary key,
    code          varchar(50)                          not null,
    name          varchar(255)                         not null,
    display_order int        default 0                 not null,
    is_active     tinyint(1) default 1                 not null,
    created_at    datetime   default CURRENT_TIMESTAMP not null,
    updated_at    datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint uq_affiliation_categories_code
        unique (code)
);

create table plango.area_capacities
(
    area                   varchar(100)         not null
        primary key,
    max_area               double               null,
    is_active              tinyint(1) default 1 not null,
    include_in_aggregation tinyint(1) default 1 not null
);

create table plango.attendance_board_members
(
    id            int unsigned auto_increment
        primary key,
    board_id      int unsigned                         not null,
    employee_id   varchar(32)                          not null,
    display_name  varchar(255)                         null,
    display_order int        default 0                 not null,
    access_info   text                                 null,
    is_active     tinyint(1) default 1                 not null,
    created_at    datetime   default CURRENT_TIMESTAMP not null,
    updated_at    datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create index idx_attendance_board_members_board_id
    on plango.attendance_board_members (board_id);

create index idx_attendance_board_members_employee_id
    on plango.attendance_board_members (employee_id);

create table plango.attendance_boards
(
    id                   int unsigned auto_increment
        primary key,
    group_name           varchar(255)                         not null,
    affiliation_category varchar(255)                         null,
    board_name           varchar(255)                         not null,
    sort_order           int        default 0                 not null,
    is_active            tinyint(1) default 1                 not null,
    created_at           datetime   default CURRENT_TIMESTAMP not null,
    updated_at           datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create index idx_attendance_boards_group_name
    on plango.attendance_boards (group_name);

create table plango.attendance_status_master
(
    id         int unsigned auto_increment
        primary key,
    code       varchar(50)                          not null,
    label      varchar(100)                         not null,
    sort_order int        default 0                 not null,
    is_active  tinyint(1) default 1                 not null,
    created_at datetime   default CURRENT_TIMESTAMP not null,
    updated_at datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint uq_attendance_status_master_code
        unique (code)
);

create table plango.attendance_statuses
(
    id          int unsigned auto_increment
        primary key,
    board_id    int unsigned                       not null,
    employee_id varchar(32)                        not null,
    status_code varchar(50)                        not null,
    memo        text                               null,
    updated_at  datetime default CURRENT_TIMESTAMP not null,
    updated_by  varchar(32)                        not null
);

create index idx_attendance_statuses_board_id
    on plango.attendance_statuses (board_id);

create index idx_attendance_statuses_employee_id
    on plango.attendance_statuses (employee_id);

create index idx_attendance_statuses_status_code
    on plango.attendance_statuses (status_code);

create table ifs_reference_data.backlog_task_date_table
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

create table ifs_reference_data.backlog_task_ids_table
(
    id                int auto_increment
        primary key,
    unique_project_id varchar(100) null,
    summary           varchar(100) null,
    issue_id          int          null,
    parent            tinyint(1)   null,
    backlog_pj_id     int          not null
);

create table ifs_reference_data.backlog_users_table
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

create table project_hub.blocks
(
    id         text null,
    page_id    text null,
    type       text null,
    content    text null,
    position   text null,
    created_at text null,
    updated_at text null
);

create table ifs_reference_data.blue_prints_table
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

create table ifs_reference_data.blueprint_kind_table
(
    blue_print_kind_id   int      not null comment '図面種別ID'
        primary key,
    blue_print_kind_name char(50) null comment '図面種別名'
)
    comment '図面種別定義テーブル';

create table ifs_reference_data.blue_print_alert_history_table
(
    id                 int auto_increment
        primary key,
    unique_project_id  varchar(20) not null comment 'ユニークプロジェクトID（プロジェクトID＋サブプロジェクトID）',
    blue_print_kind_id int         not null comment '図面種別ID',
    status             tinyint(1)  not null comment '出図状況',
    constraint blue_print_alert_history_table_blue_print_fk
        foreign key (blue_print_kind_id) references ifs_reference_data.blueprint_kind_table (blue_print_kind_id)
)
    comment '各案件ごとの出図図面一覧';

create table ifs_reference_data.blue_prints_alert_setting_table
(
    id                 int auto_increment
        primary key,
    subproject_type_id int not null comment 'サブプロジェクト種別',
    blue_print_kind_id int not null comment '図面種別ID',
    process_kind_id    int not null comment '工程ID',
    alert_offset_date  int not null comment 'アラートアクティベートのオフセット日数',
    constraint blue_prints_kind_id_fk
        foreign key (blue_print_kind_id) references ifs_reference_data.blueprint_kind_table (blue_print_kind_id)
)
    comment '図面出図におけるアラート出力オフセット設定';

create table plango.board_attachments
(
    id              int unsigned auto_increment
        primary key,
    post_id         int      null,
    filename        text     null,
    stored_filename text     null,
    file_size       int      null,
    uploaded_at     datetime null
);

create table plango.board_posts
(
    id         int unsigned auto_increment
        primary key,
    project_id int      null,
    title      text     null,
    content    text     null,
    created_by text     null,
    created_at datetime null,
    updated_at datetime null
);

create table plango.categories
(
    id          int unsigned auto_increment
        primary key,
    name        text null,
    description text null
);

create table project_hub.comments
(
    unique_project_id text null,
    se_comment        text null,
    ig_comment        text null
);

create table plango.comments
(
    unique_project_id varchar(20)   not null
        primary key,
    se_comment        varchar(999)  null,
    ig_comment        varchar(8999) null
);

create table plango.company_calendar
(
    date        date       not null
        primary key,
    is_holiday  tinyint(1) null,
    description text       null
);

create table plango.completed_projects
(
    unique_project_id varchar(20) not null
        primary key,
    complete          tinyint(1)  not null
);

create table project_hub.completed_projects
(
    unique_project_id text null,
    complete          int  null
);

create table plango.completed_todos
(
    id                   int unsigned auto_increment
        primary key,
    project_id           int                  null,
    title                text                 null,
    description          text                 null,
    priority             int                  null,
    start_date           date                 null,
    due_date             date                 null,
    progress             int                  null,
    department           text                 null,
    affiliation_category text                 null,
    completed_at         datetime             null,
    completed_by         text                 null,
    original_created_at  datetime             null,
    original_created_by  text                 null,
    assigned_to          text                 null,
    attachment           text                 null,
    attachment_filename  text                 null,
    template_id          int                  null,
    original_progress    int                  null,
    no_deadline_mail     tinyint(1) default 0 not null
);

create table plango.consumables_items
(
    id                   int unsigned auto_increment
        primary key,
    item_name            text       null,
    item_code            text       null,
    unit_price           int        null,
    remark               text       null,
    purchase_destination text       null,
    is_active            tinyint(1) null,
    created_at           datetime   null,
    updated_at           datetime   null
);

create table plango.consumables_request_details
(
    id                   int unsigned auto_increment
        primary key,
    header_id            int  null,
    item_id              int  null,
    item_name            text null,
    item_code            text null,
    unit_price           int  null,
    quantity             int  null,
    total_price          int  null,
    purchase_destination text null
);

create table plango.consumables_request_headers
(
    id                int unsigned auto_increment
        primary key,
    requester_id      text     null,
    requester_name    text     null,
    requester_group   text     null,
    requester_email   text     null,
    requester_dept_id text     null,
    requester_dept    text     null,
    requester_company text     null,
    requester_bu      text     null,
    total_amount      int      null,
    status            text     null,
    created_at        datetime null
);

create table ifs_reference_data.design_plan_table
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

create table ifs_reference_data.device_used_history_table
(
    id                int auto_increment
        primary key,
    unique_project_id char(20) null comment 'プロジェクトID＋サブプロジェクトID',
    device_id         char(10) null comment '測定器ID',
    using_start_date  datetime null comment '利用開始日',
    using_end_date    datetime null comment '利用終了日'
);

create table ifs_reference_data.drawing_status_table
(
    unique_project_id  char(20) not null
        primary key,
    blue_print_kind_id char(20) null comment '図面種別ID',
    status_id          int      null
)
    comment '図面出図状態テーブル';

create table plango.duty_item_answer_files
(
    id            int unsigned auto_increment
        primary key,
    year          int                     null,
    month         int                     null,
    group_name    varchar(255) default '' not null,
    item_id       int                     null,
    employee_id   text                    null,
    version_no    int                     null,
    original_name text                    null,
    stored_name   text                    null,
    stored_path   text                    null,
    uploaded_by   text                    null,
    uploaded_at   datetime                null,
    note          text                    null
);

create table plango.duty_item_task_files
(
    id            int unsigned auto_increment
        primary key,
    year          int                     null,
    month         int                     null,
    group_name    varchar(255) default '' not null,
    item_id       int                     null,
    file_type     text                    null,
    original_name text                    null,
    stored_name   text                    null,
    stored_path   text                    null,
    uploaded_by   text                    null,
    uploaded_at   datetime                null,
    note          text                    null
);

create table plango.duty_items
(
    id          int unsigned auto_increment
        primary key,
    name        text                    null,
    description text                    null,
    group_name  varchar(255) default '' not null,
    sort_order  int                     null,
    is_active   int                     null,
    created_at  datetime                null,
    updated_at  datetime                null
);

create table plango.duty_monthly_assignments
(
    id          int unsigned auto_increment
        primary key,
    year        int                     null,
    month       int                     null,
    group_name  varchar(255) default '' not null,
    item_id     int                     null,
    employee_id text                    null,
    note        text                    null,
    created_at  datetime                null,
    updated_at  datetime                null
);

create index idx_duty_monthly_assignments_group_name
    on plango.duty_monthly_assignments (group_name);

create table ifs_reference_data.dva_history_table
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

create table plango.equipment
(
    id                int unsigned auto_increment
        primary key,
    name              text                 null,
    category_id       int                  null,
    asset_code        text                 null,
    location          text                 null,
    manager_user_id   text                 null,
    owner_group_name  varchar(255)         null,
    remarks           text                 null,
    usage_notes       text                 null,
    approval_required int                  null,
    enabled           int                  null,
    created_at        datetime             null,
    updated_at        datetime             null,
    item1             text                 null,
    item2             text                 null,
    item3             text                 null,
    item4             text                 null,
    item5             text                 null,
    item6             text                 null,
    item7             text                 null,
    item8             text                 null,
    item9             text                 null,
    item10            text                 null,
    is_shared         tinyint(1) default 0 not null
);

create table plango.equipment_categories
(
    id          int unsigned auto_increment
        primary key,
    name        text null,
    description text null
);

create table plango.equipment_permissions
(
    id           int unsigned auto_increment
        primary key,
    equipment_id int      null,
    role         text     null,
    created_at   datetime null
);

create table plango.equipment_reservation_series
(
    id                int unsigned auto_increment
        primary key,
    equipment_id      int      null,
    created_by        text     null,
    title             text     null,
    description       text     null,
    pattern_type      text     null,
    weekday           int      null,
    month_day         int      null,
    start_date        date     null,
    end_date          date     null,
    start_time        text     null,
    end_time          text     null,
    all_day           int      null,
    approval_required int      null,
    status            text     null,
    created_at        datetime null
);

create table plango.equipment_reservations
(
    id                int unsigned auto_increment
        primary key,
    equipment_id      int        null,
    series_id         int        null,
    reserved_by       text       null,
    title             text       null,
    description       text       null,
    start_datetime    datetime   null,
    end_datetime      datetime   null,
    all_day           tinyint(1) null,
    approval_required tinyint(1) null,
    status            text       null,
    created_at        datetime   null,
    updated_at        datetime   null,
    approved_by       text       null,
    approved_at       datetime   null,
    rejected_by       text       null,
    rejected_at       datetime   null,
    cancelled_by      text       null,
    cancelled_at      datetime   null,
    item1             text       null,
    item2             text       null,
    item3             text       null,
    item4             text       null,
    item5             text       null
);

create table plango.estimate_pdfs
(
    id           int unsigned auto_increment
        primary key,
    pjid         varchar(50) null,
    subid        varchar(20) null,
    amount_yen   int         null,
    file_name    text        null,
    file_path    text        null,
    extracted_at datetime    null,
    source       text        null,
    note         text        null
);

create index idx_estimate_pdfs_pjid
    on plango.estimate_pdfs (pjid);

create table ifs_reference_data.external_users_table
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

create table project_hub.gantt_details
(
    id                int  null,
    unique_project_id text null,
    process_kind_id   int  null,
    detail_comment    text null,
    update_by         text null,
    update_date       text null
);

create table plango.gantt_details
(
    id                int auto_increment
        primary key,
    unique_project_id varchar(20) not null,
    process_kind_id   int         not null,
    detail_comment    mediumtext  null,
    update_by         varchar(10) not null,
    update_date       varchar(30) not null
);

create table plango.group_board_attachments
(
    id              int unsigned auto_increment
        primary key,
    post_id         int      null,
    filename        text     null,
    stored_filename text     null,
    file_size       int      null,
    uploaded_at     datetime null
);

create table plango.group_board_posts
(
    id         int unsigned auto_increment
        primary key,
    project_id int      null,
    title      text     null,
    content    text     null,
    created_by text     null,
    created_at datetime null,
    updated_at datetime null
);

create table ifs_reference_data.group_kind_table
(
    jrc_group_id   int      not null comment 'グループID'
        primary key,
    jrc_group_name char(50) null comment 'グループ名',
    jrc_group_code char(20) null comment 'グループコード'
)
    comment 'グループ種別定義テーブル';

create table plango.group_project_issue_attachments
(
    id              int unsigned auto_increment
        primary key,
    issue_id        int      null,
    filename        text     null,
    stored_filename text     null,
    file_size       int      null,
    uploaded_at     datetime null
);

create table plango.group_project_issues
(
    id          int unsigned auto_increment
        primary key,
    project_id  int        null,
    title       text       null,
    description text       null,
    solution    text       null,
    department  text       null,
    assignee    text       null,
    due_date    date       null,
    progress    int        null,
    status      text       null,
    priority    text       null,
    notes       text       null,
    completed   tinyint(1) null,
    created_by  text       null,
    updated_by  text       null,
    created_at  datetime   null,
    updated_at  datetime   null
);

create table plango.group_project_todo_attachments
(
    id              int unsigned auto_increment
        primary key,
    todo_id         int      null,
    filename        text     null,
    stored_filename text     null,
    file_size       int      null,
    uploaded_at     datetime null
);

create table plango.group_project_todos
(
    id           int unsigned auto_increment
        primary key,
    project_id   int        null,
    title        text       null,
    description  text       null,
    assignee     text       null,
    priority     text       null,
    due_date     date       null,
    progress     int        null,
    is_completed tinyint(1) null,
    created_by   text       null,
    created_at   datetime   null,
    updated_at   datetime   null,
    completed_at datetime   null
);

create table plango.group_projects
(
    id               int unsigned auto_increment
        primary key,
    title            text                                null,
    category         text                                null,
    manager          text                                null,
    members          text                                null,
    status           text                                null,
    owner_group_name varchar(255)                        null,
    created_at       timestamp default CURRENT_TIMESTAMP not null,
    updated_at       timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    creator          text                                null
);

create table ifs_reference_data.ifs_components_table
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

create table ifs_reference_data.ifs_projects_table
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

create table plango.info_board_attachments
(
    id              int unsigned auto_increment
        primary key,
    post_id         int      null,
    filename        text     null,
    stored_filename text     null,
    file_size       int      null,
    uploaded_at     datetime null
);

create table plango.info_board_posts
(
    id         int unsigned auto_increment
        primary key,
    title      text     null,
    content    text     null,
    created_by text     null,
    created_at datetime null,
    updated_at datetime null
);

create table ifs_reference_data.information_equipment_assign_table
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

create table plango.inspection_areas
(
    id         int unsigned auto_increment
        primary key,
    code       text null,
    name       text null,
    sort_order int  null,
    is_active  int  null
);

create table plango.inspection_locations
(
    id                int unsigned auto_increment
        primary key,
    area_id           int      null,
    description       text     null,
    pdf_filename      text     null,
    original_filename text     null,
    created_at        datetime null,
    updated_at        datetime null
);

create table plango.inspection_photos
(
    id                 int auto_increment
        primary key,
    component_id       int                                null,
    filename           varchar(255)                       not null,
    original_name      varchar(255)                       not null,
    mime_type          varchar(100)                       not null,
    file_size          int                                not null,
    created_at         datetime default CURRENT_TIMESTAMP not null,
    created_by         varchar(50)                        null,
    ifs_project_id     varchar(50)                        null,
    ifs_sub_project_id varchar(50)                        null,
    ifs_row_no         varchar(50)                        null
);

create index idx_inspection_photos_component_id
    on plango.inspection_photos (component_id);

create table plango.inspection_sheets
(
    id             int auto_increment
        primary key,
    project_id     varchar(255)                          not null,
    sub_project_id varchar(255)                          null,
    customer_name  varchar(255)                          null,
    item_name      varchar(255)                          null,
    product_name   varchar(255)                          null,
    model_name     varchar(255)                          null,
    order_no       varchar(255)                          null,
    quantity       varchar(50)                           null,
    mouths         varchar(50)                           null,
    system_name    varchar(255)                          null,
    status         varchar(20) default 'not_inspected'   null,
    inspector      varchar(255)                          null,
    created_at     timestamp   default CURRENT_TIMESTAMP null,
    updated_at     timestamp   default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP
);

create table plango.instrument_import_error_rows
(
    id            bigint auto_increment
        primary key,
    import_log_id bigint                             not null,
    row_index     int                                not null,
    management_no varchar(255)                       not null,
    message       text                               not null,
    created_at    datetime default CURRENT_TIMESTAMP not null
);

create index idx_instrument_import_error_rows_import_log_id
    on plango.instrument_import_error_rows (import_log_id);

create table plango.instrument_import_logs
(
    id            bigint auto_increment
        primary key,
    imported_at   datetime                           not null,
    file_name     varchar(255)                       not null,
    inserted      int                                not null,
    updated       int                                not null,
    errors        int                                not null,
    error_summary text                               null,
    created_at    datetime default CURRENT_TIMESTAMP not null
);

create table plango.instrument_usage_headers
(
    id              int unsigned auto_increment
        primary key,
    inspection_date date                               null,
    temperature     double                             null,
    humidity        double                             null,
    env_device_id   int                                null,
    env_timestamp   datetime                           null,
    project_id      text                               null,
    sub_project_id  text                               null,
    subject         text                               null,
    created_by      text                               null,
    created_at      datetime default CURRENT_TIMESTAMP null,
    updated_at      datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP,
    case_name       text                               null,
    status          text                               null,
    completed_by    text                               null,
    completed_at    datetime                           null
);

create table plango.instrument_usage_items
(
    id                   int unsigned auto_increment
        primary key,
    header_id            int  null,
    row_no               int  null,
    instrument_id        int  null,
    name                 text null,
    model                text null,
    maker                text null,
    management_no        text null,
    calibration_valid_ym text null,
    remark               text null,
    created_at           text null,
    updated_at           text null
);

create table plango.issue_attachments
(
    id              int unsigned auto_increment
        primary key,
    issue_id        int      null,
    filename        text     null,
    stored_filename text     null,
    file_size       int      null,
    uploaded_at     datetime null
);

create table plango.issues
(
    id                           int unsigned auto_increment
        primary key,
    project_id                   int                  null,
    title                        text                 null,
    description                  text                 null,
    status                       text                 null,
    priority                     text                 null,
    created_by                   text                 null,
    created_at                   datetime             null,
    updated_at                   datetime             null,
    measures                     text                 null,
    department                   text                 null,
    affiliation_category         varchar(255)         null,
    group_name                   varchar(255)         null,
    person_in_charge             text                 null,
    person_in_charge_employee_id varchar(32)          null,
    person_in_charge_name        text                 null,
    person_in_charge_free        text                 null,
    deadline                     date                 null,
    progress                     int                  null,
    updated_by                   text                 null,
    remarks                      text                 null,
    disable_email_notification   tinyint(1) default 0 not null,
    overdue_notified_count       int        default 0 not null,
    last_overdue_notified_at     datetime             null
);

create table plango.job_types
(
    id            int auto_increment
        primary key,
    code          varchar(50)   not null,
    name          varchar(255)  not null,
    display_order int default 0 null,
    constraint uq_job_types_code
        unique (code)
);

create table ifs_reference_data.jrc_users_table
(
    jrc_user_code    char(10) not null comment '個人コード'
        primary key,
    jrc_user_name    char(50) null comment 'ユーザー名',
    jrc_mail_address char(50) null comment 'メールアドレス',
    jrc_group_id     int      null comment 'グループID',
    constraint jrc_users_table_group_kind_table_jrc_group_id_fk
        foreign key (jrc_group_id) references ifs_reference_data.group_kind_table (jrc_group_id)
);

create table plango.labels
(
    id         int unsigned auto_increment
        primary key,
    data_json  text     null,
    created_at datetime null,
    updated_at datetime null
);

create table plango.layouts
(
    id            int unsigned auto_increment
        primary key,
    filename      text     null,
    original_name text     null,
    project       text     null,
    usage_text    text     null,
    remark        text     null,
    created_at    datetime null,
    updated_at    datetime null
);

create table plango.ledger_entries
(
    id               int auto_increment
        primary key,
    ledger_layout_id int                                not null,
    group_id         int                                not null,
    control_no       varchar(64)                        not null,
    title            varchar(255)                       null,
    data_json        json                               not null,
    issue_date       date                               null,
    created_at       datetime default CURRENT_TIMESTAMP not null,
    created_by       varchar(64)                        null,
    updated_at       datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    updated_by       varchar(64)                        null,
    constraint uq_ledger_entries_control_no
        unique (control_no)
);

create index idx_ledger_entries_ledger_layout_id
    on plango.ledger_entries (ledger_layout_id);

create table plango.ledger_group_settings
(
    id               int auto_increment
        primary key,
    group_id         int                                  not null,
    group_name       varchar(255)                         not null,
    ledger_layout_id int                                  not null,
    dept_code        varchar(8)                           not null,
    group_code       varchar(8)                           not null,
    active_flag      tinyint(1) default 1                 not null,
    created_at       datetime   default CURRENT_TIMESTAMP not null,
    created_by       varchar(64)                          null,
    updated_at       datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    updated_by       varchar(64)                          null,
    group_code1      varchar(8)                           null,
    group_code2      varchar(8)                           null,
    group_code3      varchar(8)                           null,
    group_code4      varchar(8)                           null,
    group_code5      varchar(8)                           null
);

create index idx_ledger_group_settings_group_id
    on plango.ledger_group_settings (group_id);

create index idx_ledger_group_settings_ledger_layout_id
    on plango.ledger_group_settings (ledger_layout_id);

create table plango.ledger_layouts
(
    id            int auto_increment
        primary key,
    ledger_code   varchar(16)                          not null,
    type_no       varchar(8)                           not null,
    name          varchar(255)                         not null,
    description   text                                 null,
    columns_json  json                                 not null,
    template_path varchar(512)                         null,
    active_flag   tinyint(1) default 1                 not null,
    created_at    datetime   default CURRENT_TIMESTAMP not null,
    created_by    varchar(64)                          null,
    updated_at    datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    updated_by    varchar(64)                          null,
    constraint uq_ledger_layouts_ledger_code
        unique (ledger_code)
);

create table plango.ledger_numbering_counters
(
    id          int auto_increment
        primary key,
    group_id    int                                  not null,
    ledger_code varchar(16)                          not null,
    year1       char                                 not null,
    group_code  varchar(8) default ''                not null,
    current_seq int        default 0                 not null,
    updated_at  datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create index idx_ledger_numbering_counters_group_id
    on plango.ledger_numbering_counters (group_id);

create table plango.login_logs
(
    id           int auto_increment
        primary key,
    employee_id  varchar(50)  not null,
    name         varchar(255) not null,
    group_name   varchar(255) null,
    company_name varchar(255) null,
    login_at     datetime     not null
);

create index idx_login_logs_employee_id
    on plango.login_logs (employee_id);

create index idx_login_logs_login_at
    on plango.login_logs (login_at);

create table plango.mail_lists
(
    id                int unsigned auto_increment
        primary key,
    owner_employee_id text null,
    name              text null,
    to_list           text null,
    cc_list           text null,
    bcc_list          text null,
    created_at        text null,
    updated_at        text null
);

create table plango.manual_attachment_views
(
    id            int unsigned auto_increment
        primary key,
    attachment_id int      null,
    user_id       text     null,
    downloaded_at datetime null
);

create table plango.manual_attachments
(
    id             int unsigned auto_increment
        primary key,
    manual_id      int      null,
    file_path      text     null,
    file_name      text     null,
    original_name  text     null,
    created_at     datetime null,
    download_count int      null
);

create table plango.manual_views
(
    id        int unsigned auto_increment
        primary key,
    manual_id int      null,
    user_id   text     null,
    viewed_at datetime null
);

create table plango.manuals
(
    id               int unsigned auto_increment
        primary key,
    title            text                 null,
    category         text                 null,
    description      text                 null,
    file_path        text                 null,
    file_name        text                 null,
    original_name    text                 null,
    posted_at        datetime             null,
    created_at       datetime             null,
    created_by       text                 null,
    owner_group_name varchar(255)         null,
    is_shared        tinyint(1) default 1 not null,
    updated_at       datetime             null,
    updated_by       text                 null,
    status           text                 null,
    view_count       int                  null,
    download_count   int                  null
);

create table ifs_reference_data.measuring_device_kind_table
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

create table ifs_reference_data.device_assign_table
(
    jrc_user_code char(10)    not null comment '個人コード'
        primary key,
    device_id     varchar(10) null comment '測定器ID',
    constraint device_assign_table_measuring_device_kind_table_device_id_fk
        foreign key (device_id) references ifs_reference_data.measuring_device_kind_table (device_id)
)
    comment '機器割り当て用テーブル';

create table plango.measuring_instrument_usage_history
(
    id                   int unsigned auto_increment
        primary key,
    instrument_id        int      null,
    usage_type           text     null,
    project_category     text     null,
    borrower_employee_id text     null,
    borrower_name        text     null,
    borrower_department  text     null,
    user_employee_id     text     null,
    user_name            text     null,
    user_department      text     null,
    loan_start_date      date     null,
    loan_end_date        date     null,
    planned_end_date     date     null,
    status               text     null,
    created_at           datetime null,
    updated_at           datetime null,
    usage_location       text     null,
    calibration_result   text     null,
    attachment_path      text     null,
    calibration_comment  text     null
);

create table plango.measuring_instruments
(
    id                          int unsigned auto_increment
        primary key,
    management_no               text                 null,
    management_company_name     text                 null,
    item_name                   text                 null,
    serial_no                   text                 null,
    maker_info                  text                 null,
    model_name                  text                 null,
    instrument_category         text                 null,
    management_class_1          text                 null,
    management_class_2          text                 null,
    operation_class_1           text                 null,
    operation_class_2           text                 null,
    performance                 text                 null,
    accessories                 text                 null,
    instructions                text                 null,
    asset_category              text                 null,
    owner_department            text                 null,
    fixed_asset_ref             text                 null,
    purchase_order_no           text                 null,
    storage_department          text                 null,
    storage_location            text                 null,
    budget_order_no             text                 null,
    manager_primary             text                 null,
    manager_secondary           text                 null,
    extension_number            text                 null,
    calibration_required        text                 null,
    calibration_type            text                 null,
    calibration_agency_type     text                 null,
    calibration_performed_date  date                 null,
    calibration_interval_months int                  null,
    calibration_next_due_date   date                 null,
    overdue_notified            tinyint(1) default 0 not null,
    overdue_notified_at         datetime             null,
    calibration_responsible     text                 null,
    calibration_agency          text                 null,
    status                      text                 null,
    created_at                  datetime             null,
    updated_at                  datetime             null,
    acquisition_date            date                 null,
    acquisition_price           double               null,
    loan_status                 text                 null,
    loan_start_date             date                 null,
    loan_due_date               date                 null,
    loan_project_category       text                 null,
    loan_borrower_id            text                 null,
    loan_borrower_name          text                 null,
    loan_user_id                text                 null,
    loan_user_name              text                 null
);

create table plango.notices
(
    id          int unsigned auto_increment
        primary key,
    notice_date date     null,
    importance  text     null,
    title       text     null,
    content     text     null,
    created_at  datetime null,
    updated_at  datetime null
);

create table ifs_reference_data.nulab_accounts_table
(
    id        int auto_increment
        primary key,
    user_id   varchar(50)  not null,
    nulab_id  varchar(100) null,
    name      varchar(100) null,
    unique_id varchar(100) null,
    constraint nulab_accounts_table_ibfk_1
        foreign key (user_id) references ifs_reference_data.backlog_users_table (userId)
            on delete cascade
);

create index user_id
    on ifs_reference_data.nulab_accounts_table (user_id);

create table plango.outsourcing_costs
(
    id             bigint auto_increment
        primary key,
    expense_month  varchar(7)                         not null,
    external_id    varchar(50)                        not null,
    external_name  varchar(100)                       not null,
    amount_yen     bigint                             not null,
    project_id     varchar(50)                        not null,
    sub_project_id varchar(50)                        not null,
    created_at     datetime default CURRENT_TIMESTAMP not null,
    updated_at     datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create index idx_outsourcing_costs_expense_month
    on plango.outsourcing_costs (expense_month);

create index idx_outsourcing_costs_project_id
    on plango.outsourcing_costs (project_id);

create table plango.overtime_alert_logs
(
    id                  int unsigned auto_increment
        primary key,
    employee_id         text     null,
    alert_type          text     null,
    period_start        text     null,
    period_end          text     null,
    first_exceeded_date text     null,
    last_notified_date  text     null,
    notify_count        int      null,
    created_at          datetime null,
    updated_at          datetime null
);

create table plango.overtime_overlimit_requests
(
    id                int unsigned auto_increment
        primary key,
    employee_id       text     null,
    year              int      null,
    month             int      null,
    chk_2m_140h       int      null,
    chk_1m_45_80h     int      null,
    chk_holiday_3days int      null,
    chk_15days_streak int      null,
    chk_1m_night_15h  int      null,
    chk_year_360_720h int      null,
    note              text     null,
    status            text     null,
    proxy_employee_id text     null,
    created_at        datetime null
);

create table plango.overtime_plans
(
    id                     int unsigned auto_increment
        primary key,
    employee_id            text     null,
    date                   date     null,
    planned_normal_minutes int      null,
    planned_early_minutes  int      null,
    planned_night_minutes  int      null,
    note                   text     null,
    created_at             datetime null,
    updated_at             datetime null
);

create table plango.overtime_requests
(
    id                            int unsigned auto_increment
        primary key,
    employee_id                   text                                null,
    group_code                    text                                null,
    group_name                    text                                null,
    date                          date                                null,
    start_time                    text                                null,
    end_time                      text                                null,
    duration_minutes              int                                 null,
    duration_hours_exact          double                              null,
    duration_hours_round_0_25     double                              null,
    duration_hours_0_017          double                              null,
    weekday_minutes               int                                 null,
    holiday_minutes               int                                 null,
    night_minutes                 int                                 null,
    weekday_normal_minutes        int                                 null,
    weekday_early_minutes         int                                 null,
    weekday_night_minutes         int                                 null,
    holiday_normal_minutes        int                                 null,
    holiday_early_minutes         int                                 null,
    holiday_night_minutes         int                                 null,
    status                        text                                null,
    reason                        text                                null,
    comment                       text                                null,
    category                      text                                null,
    proxy_employee_id             text                                null,
    approver_id                   text                                null,
    approver_comment              text                                null,
    approved_at                   timestamp                           null,
    created_at                    timestamp default CURRENT_TIMESTAMP null,
    updated_at                    timestamp default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP,
    actual_start_time             text                                null,
    actual_end_time               text                                null,
    actual_duration_minutes       int                                 null,
    actual_weekday_normal_minutes int                                 null,
    actual_weekday_early_minutes  int                                 null,
    actual_weekday_night_minutes  int                                 null,
    actual_holiday_normal_minutes int                                 null,
    actual_holiday_early_minutes  int                                 null,
    actual_holiday_night_minutes  int                                 null,
    actual_recorded_at            timestamp                           null,
    actual_comment                text                                null,
    daikyu_planned_date           date                                null
);

create table plango.page_views
(
    id          int unsigned auto_increment
        primary key,
    page_name   text     null,
    view_count  int      null,
    last_viewed datetime null
);

create table project_hub.pages
(
    id         text null,
    title      text null,
    icon       text null,
    parent_id  text null,
    type       text null,
    created_at text null,
    updated_at text null
);

create table plango.pages
(
    id         int auto_increment
        primary key,
    title      varchar(255)                        not null,
    icon       varchar(255)                        null,
    parent_id  int                                 null,
    type       varchar(50)                         not null,
    created_at timestamp default CURRENT_TIMESTAMP null,
    updated_at timestamp default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP,
    constraint pages_ibfk_1
        foreign key (parent_id) references plango.pages (id)
            on delete set null
);

create table plango.blocks
(
    id         int auto_increment
        primary key,
    page_id    int                                 not null,
    type       varchar(50)                         not null,
    content    text                                null,
    position   int                                 not null,
    created_at timestamp default CURRENT_TIMESTAMP null,
    updated_at timestamp default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP,
    constraint blocks_ibfk_1
        foreign key (page_id) references plango.pages (id)
            on delete cascade
);

create index page_id
    on plango.blocks (page_id);

create index parent_id
    on plango.pages (parent_id);

create table project_hub.partial_shipment
(
    unique_project_id   text null,
    partial_ship_date_1 text null,
    partial_ship_date_2 text null,
    partial_ship_date_3 text null,
    partial_ship_date_4 text null,
    partial_ship_date_5 text null,
    partial_ship_date_6 text null,
    partial_ship_date_7 text null,
    partial_ship_date_8 text null,
    partial_ship_date_9 text null
);

create table plango.partial_shipment
(
    unique_project_id   varchar(10) not null
        primary key,
    partial_ship_date_1 date        null,
    partial_ship_date_2 date        null,
    partial_ship_date_3 date        null,
    partial_ship_date_4 date        null,
    partial_ship_date_5 date        null,
    partial_ship_date_6 date        null,
    partial_ship_date_7 date        null,
    partial_ship_date_8 date        null,
    partial_ship_date_9 date        null
);

create table plango.pending_projects
(
    id                      bigint unsigned auto_increment
        primary key,
    pending_code            varchar(50)                           null,
    project_id              varchar(50)                           not null,
    sub_project_id          varchar(50)                           null,
    sub3_id                 varchar(3)                            null,
    owner_group_name        varchar(255)                          null,
    client_name             text                                  not null,
    project_title           text                                  not null,
    sales_manager           text                                  null,
    person_in_charge        text                                  null,
    admin_manager           text                                  null,
    worker                  text                                  null,
    expected_amount_yen     bigint                                null,
    order_probability_level varchar(10)                           null,
    expected_order_date     date                                  null,
    inspection_date         date                                  null,
    witness_start_date1     date                                  null,
    witness_end_date1       date                                  null,
    witness_start_date2     date                                  null,
    witness_end_date2       date                                  null,
    witness_start_date3     date                                  null,
    witness_end_date3       date                                  null,
    shipping_date           date                                  null,
    status                  varchar(20) default 'pending'         not null,
    note                    text                                  null,
    created_at              datetime    default CURRENT_TIMESTAMP not null,
    updated_at              datetime    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    created_by              text                                  null,
    updated_by              text                                  null
);

create index idx_pending_projects_owner_group_name
    on plango.pending_projects (owner_group_name);

create index idx_pending_projects_project_id
    on plango.pending_projects (project_id);

create index idx_pending_projects_status
    on plango.pending_projects (status);

create index idx_pending_projects_sub3_id
    on plango.pending_projects (sub3_id);

create table ifs_reference_data.pending_table
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

create table plango.personal_todos
(
    id                  int unsigned auto_increment
        primary key,
    user_id             text     null,
    title               text     null,
    description         text     null,
    due_date            date     null,
    priority            int      null,
    status              text     null,
    progress            int      null,
    attachment          text     null,
    attachment_filename text     null,
    created_at          datetime null,
    updated_at          datetime null,
    completed_at        datetime null
);

create table ifs_reference_data.process_kind_table
(
    process_kind_id   int      not null comment '工程区分ID'
        primary key,
    process_kind_name char(50) null comment '工程区分名'
)
    comment '工程区分定義テーブル';

create table ifs_reference_data.production_process_table
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

create table ifs_reference_data.project_assign_table
(
    id                int auto_increment
        primary key,
    unique_project_id char(20)   null comment 'プロジェクトID＋サブプロジェクトID',
    jrc_user_code     char(20)   null comment '個人コード',
    inspection_ready  tinyint(1) null comment '検査可能判定'
);

create table plango.project_chat_messages
(
    id                 int unsigned auto_increment
        primary key,
    project_id         varchar(255)                         not null,
    sub_project_id     varchar(255)                         null,
    sender_employee_id varchar(32)                          not null,
    sender_name        varchar(255)                         not null,
    message            text                                 not null,
    created_at         datetime   default CURRENT_TIMESTAMP not null,
    updated_at         datetime                             null,
    updated_by         varchar(255)                         null,
    is_deleted         tinyint(1) default 0                 not null,
    deleted_at         datetime                             null,
    deleted_by         varchar(255)                         null
);

create index idx_project_chat_messages_project_id
    on plango.project_chat_messages (project_id);

create index idx_project_chat_messages_sender_employee_id
    on plango.project_chat_messages (sender_employee_id);

create table ifs_reference_data.project_full_merged_table_work
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

create table ifs_reference_data.project_full_merged_tmp
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

create table plango.project_ifs_items
(
    id                          bigint unsigned auto_increment
        primary key,
    project_id                  varchar(20)                         not null,
    sub_project_id              varchar(20)                         null,
    site                        varchar(50)                         null,
    row_no                      varchar(50)                         not null,
    item_code                   varchar(100)                        null,
    item_name                   varchar(255)                        null,
    requested_date              date                                null,
    requested_qty               decimal(18, 4)                      null,
    order_method                varchar(50)                         null,
    order_progress              varchar(50)                         null,
    status                      varchar(50)                         null,
    supply_option               varchar(50)                         null,
    standard_item               varchar(100)                        null,
    model_name                  varchar(255)                        null,
    serial_no                   varchar(100)                        null,
    assembly_sign               varchar(50)                         null,
    power_name                  varchar(255)                        null,
    paint_color                 varchar(255)                        null,
    instruction_sign_name       varchar(255)                        null,
    destination                 varchar(255)                        null,
    destination_name            varchar(255)                        null,
    shipping_item_sign          varchar(50)                         null,
    previous_send_sign_name     varchar(255)                        null,
    instruction                 text                                null,
    shipping_flag               varchar(10)                         null,
    expense_type                varchar(50)                         null,
    planned_cost                decimal(18, 4)                      null,
    supplier_code               varchar(50)                         null,
    supplier_name               varchar(255)                        null,
    supplier_planned_unit_price decimal(18, 4)                      null,
    order_date                  date                                null,
    ordered_qty                 decimal(18, 4)                      null,
    allocated_qty               decimal(18, 4)                      null,
    received_date               date                                null,
    received_qty                decimal(18, 4)                      null,
    issued_date                 date                                null,
    issued_qty                  decimal(18, 4)                      null,
    issue_instruction_date      date                                null,
    issue_instruction_qty       decimal(18, 4)                      null,
    issue_destination           varchar(255)                        null,
    slip_number                 varchar(100)                        null,
    issue_instruction_reg_date  date                                null,
    transport_instruction_date  date                                null,
    transport_type              varchar(50)                         null,
    transport_instruction_qty   decimal(18, 4)                      null,
    transport_dest_name         varchar(255)                        null,
    export_flag                 varchar(10)                         null,
    transport_slip_number       varchar(100)                        null,
    transport_reg_date          date                                null,
    shipping_request_count      decimal(18, 4)                      null,
    shipping_request_qty        decimal(18, 4)                      null,
    shipping_instruction_qty    decimal(18, 4)                      null,
    shipping_status             varchar(50)                         null,
    shipping_date               date                                null,
    shipped_qty                 decimal(18, 4)                      null,
    shipping_base               varchar(50)                         null,
    shipping_info_id            varchar(100)                        null,
    arrival_request_date        date                                null,
    has_extra_instruction       varchar(10)                         null,
    purchase_request_number     varchar(100)                        null,
    purchase_order_number       varchar(100)                        null,
    manufacturing_order_number  varchar(100)                        null,
    product_serial_id           varchar(100)                        null,
    created_at_ifs              date                                null,
    created_by_ifs              varchar(100)                        null,
    updated_at_ifs              date                                null,
    updated_by_ifs              varchar(100)                        null,
    model_type                  varchar(255)                        null,
    created_at                  timestamp default CURRENT_TIMESTAMP not null,
    updated_at                  timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create index idx_project_ifs_items_project_id
    on plango.project_ifs_items (project_id);

create table project_hub.project_manage_table
(
    unique_project_id        text null,
    client_name              text null,
    contract_deadline        text null,
    shipping_approval_date   text null,
    progress                 text null,
    area_used                text null,
    deployment_location      text null,
    business_trip_start_date text null,
    business_trip_end_date   text null,
    technical_manager        text null,
    admin_manager            text null,
    person_in_charge         text null,
    worker                   text null,
    support_staff            text null,
    case_name                text null,
    source_inspection        text null,
    equipment_configuration  text null,
    resource_registration    text null,
    cost_thousand_yen        text null,
    man_hours                text null,
    used_man_hours           text null,
    comment                  text null
);

create table plango.project_manage_table
(
    unique_project_id        varchar(20)  not null
        primary key,
    client_name              varchar(255) null,
    contract_deadline        date         null,
    shipping_approval_date   date         null,
    progress                 int          null,
    area_used                float        null,
    deployment_location      varchar(255) null,
    business_trip_start_date date         null,
    business_trip_end_date   date         null,
    technical_manager        varchar(255) null,
    admin_manager            varchar(255) null,
    person_in_charge         varchar(255) null,
    worker                   varchar(255) null,
    support_staff            varchar(255) null,
    case_name                varchar(255) null,
    source_inspection        tinyint(1)   null,
    equipment_configuration  text         null,
    resource_registration    tinyint(1)   null,
    cost_thousand_yen        int          null,
    man_hours                int          null,
    used_man_hours           float        null,
    comment                  text         null
);

create table plango.project_management
(
    unique_project_id        varchar(10)                        not null comment 'ユニークプロジェクトID'
        primary key,
    client_name              varchar(255)                       null comment '顧客名',
    contract_deadline        date                               null comment '契約納期',
    shipping_approval_date   date                               null comment '出荷承認日',
    progress                 varchar(255)                       null comment '進捗',
    area_used                varchar(255)                       null comment '使用エリア',
    deployment_location      varchar(255)                       null comment '配備先',
    business_trip_start_date date                               null comment '出張開始日',
    business_trip_end_date   date                               null comment '出張終了日',
    technical_manager        varchar(255)                       null comment '技術担当',
    admin_manager            varchar(255)                       null comment '管理担当',
    person_in_charge         varchar(255)                       null comment '担当者',
    worker                   varchar(255)                       null comment '作業者',
    support_staff            varchar(255)                       null comment '支援者',
    case_name                varchar(255)                       null comment '案件名',
    man_hours                decimal(10, 2)                     null comment '予定工数',
    used_man_hours           decimal(10, 2)                     null comment '使用工数',
    comment                  text                               null comment 'コメント',
    created_at               datetime default CURRENT_TIMESTAMP not null comment '作成日時',
    updated_at               datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新日時'
)
    comment 'プロジェクト管理';

create table project_hub.project_management
(
    unique_project_id        text null,
    client_name              text null,
    contract_deadline        text null,
    shipping_approval_date   text null,
    progress                 text null,
    area_used                text null,
    deployment_location      text null,
    business_trip_start_date text null,
    business_trip_end_date   text null,
    technical_manager        text null,
    admin_manager            text null,
    person_in_charge         text null,
    worker                   text null,
    support_staff            text null,
    case_name                text null,
    man_hours                text null,
    used_man_hours           text null,
    comment                  text null,
    created_at               text null,
    updated_at               text null
);

create table plango.project_order_components
(
    id                    int auto_increment
        primary key,
    project_id            varchar(255)                        not null,
    sub_project_id        varchar(255)                        not null,
    order_number          varchar(255)                        not null,
    order_row_no          varchar(50)                         null,
    contract_detail_no    varchar(50)                         null,
    contract_type         varchar(50)                         null,
    new_case_status       varchar(50)                         null,
    ifs_status            varchar(50)                         null,
    shipping_status       varchar(50)                         null,
    is_completed          tinyint(1)                          null,
    tehai_name            varchar(255)                        null,
    model_name            varchar(255)                        null,
    dept_code             varchar(50)                         null,
    item_type_code        varchar(50)                         null,
    component_row_no      varchar(50)                         null,
    component_type        varchar(50)                         null,
    on_hold               tinyint(1)                          null,
    is_cancelled          tinyint(1)                          null,
    requested_date        date                                null,
    stock_code            varchar(100)                        null,
    item_name             varchar(255)                        null,
    expense_type          varchar(50)                         null,
    prev_quantity         decimal(18, 4)                      null,
    quantity              decimal(18, 4)                      null,
    unit_price            decimal(18, 5)                      null,
    planned_material_cost decimal(18, 5)                      null,
    actual_material_cost  decimal(18, 5)                      null,
    supplier_code         varchar(100)                        null,
    supplier_name         varchar(255)                        null,
    instruction           text                                null,
    contract_row_no       varchar(50)                         null,
    document_no           varchar(255)                        null,
    construction_code     varchar(255)                        null,
    created_at            timestamp default CURRENT_TIMESTAMP null,
    updated_at            timestamp default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP,
    inspection_date       date                                null,
    inspector_id          varchar(50)                         null,
    inspector_name        varchar(255)                        null,
    shipment_date         date                                null,
    shipper_id            varchar(50)                         null,
    shipper_name          varchar(255)                        null,
    remark                text                                null,
    inspection_packages   int                                 null,
    appearance_check      varchar(10)                         null,
    care_mark             varchar(10)                         null,
    receiver_id           varchar(20)                         null,
    receiver_name         varchar(100)                        null,
    last_updated_at       timestamp                           null,
    last_updated_by       varchar(50)                         null,
    last_updated_by_name  varchar(100)                        null
);

create index idx_project_order_components_dept_code
    on plango.project_order_components (dept_code);

create index idx_project_order_components_order_number
    on plango.project_order_components (order_number);

create index idx_project_order_components_project_id
    on plango.project_order_components (project_id);

create table plango.projects
(
    id         int unsigned auto_increment
        primary key,
    page_id    int  null,
    start_date date null,
    end_date   date null
);

create table plango.qa
(
    id            int auto_increment
        primary key,
    question      text                                not null,
    answer        text                                null,
    created_at    timestamp default CURRENT_TIMESTAMP null,
    answered_at   timestamp                           null,
    questioner_id varchar(255)                        not null,
    answerer_id   varchar(255)                        null
);

create table project_hub.qa
(
    id            text null,
    question      text null,
    answer        text null,
    created_at    text null,
    answered_at   text null,
    questioner_id text null,
    answerer_id   text null
);

create index answerer_id
    on plango.qa (answerer_id);

create index questioner_id
    on plango.qa (questioner_id);

create table plango.qa_attachments
(
    id          int unsigned auto_increment
        primary key,
    qa_id       int                                 null,
    file_name   text                                null,
    file_path   text                                null,
    file_type   text                                null,
    file_size   int                                 null,
    uploaded_at timestamp default CURRENT_TIMESTAMP not null
);

create table plango.qa_topics
(
    id         int unsigned auto_increment
        primary key,
    title      text     null,
    category1  text     null,
    category2  text     null,
    creator_id text     null,
    created_at datetime null
);

create table ifs_reference_data.reference_number_table
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

create table ifs_reference_data.required_drawing_types_table
(
    id                   int auto_increment
        primary key,
    sub_project_type     varchar(10) null comment 'サブプロジェクト種別',
    required_drawing_ids varchar(30) null comment '図面種別ID'
)
    comment '各サブプロジェクト種別ごとに必須な図面種別設定テーブル';

create table ifs_reference_data.shipment_authorization_history_table
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

create table plango.shipping_master
(
    id                    int auto_increment
        primary key,
    print_flag            tinyint(1) default 1                 not null,
    jrc_logo_flag         tinyint(1) default 0                 not null,
    project_id            varchar(255)                         not null,
    sub_project_id        varchar(255)                         null,
    tag_no                varchar(255)                         not null,
    display_order         int                                  null,
    case_no               varchar(255)                         null,
    customer              varchar(255)                         null,
    product_name          varchar(255)                         null,
    ship_to               varchar(255)                         null,
    description_1         varchar(255)                         null,
    description_2         varchar(255)                         null,
    model_name            varchar(255)                         null,
    remarks               text                                 null,
    serial_no             varchar(255)                         null,
    unique_no             varchar(255)                         null,
    quantity              int                                  null,
    split_no              int                                  null,
    divides_by            int                                  null,
    workplace_name        varchar(255)                         null,
    shipping_label        varchar(255)                         null,
    qr_data               varchar(1024)                        null,
    factory_worker_at     datetime                             null,
    factory_worker_id     varchar(255)                         null,
    factory_worker_name   varchar(255)                         null,
    factory_manager_at    datetime                             null,
    factory_manager_id    varchar(255)                         null,
    factory_manager_name  varchar(255)                         null,
    logistics_at          datetime                             null,
    logistics_id          varchar(255)                         null,
    logistics_name        varchar(255)                         null,
    site_at               datetime                             null,
    site_id               varchar(255)                         null,
    site_name             varchar(255)                         null,
    label_printed_at      datetime                             null,
    label_printed_by_id   varchar(255)                         null,
    label_printed_by_name varchar(255)                         null,
    label_print_count     int        default 0                 not null,
    component_id          int                                  null,
    component_row_no      varchar(255)                         null,
    created_at            timestamp  default CURRENT_TIMESTAMP null,
    updated_at            timestamp  default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP,
    constraint uq_shipping_master_component_id
        unique (component_id)
);

create index idx_shipping_master_project_id
    on plango.shipping_master (project_id);

create table plango.skill_business_types
(
    id            int auto_increment
        primary key,
    name          varchar(255)  not null,
    description   text          null,
    display_order int default 0 null,
    job_type_id   int           null,
    constraint uq_skill_business_types_name
        unique (name)
);

create index idx_skill_business_types_job_type_id
    on plango.skill_business_types (job_type_id);

create table plango.skill_evaluation_levels
(
    id            int auto_increment
        primary key,
    level_code    varchar(10)   not null,
    label         varchar(255)  not null,
    description   text          null,
    display_order int default 0 null,
    constraint uq_skill_evaluation_levels_level_code
        unique (level_code)
);

create table plango.skills
(
    id                        int auto_increment
        primary key,
    group_name                varchar(255)  not null,
    skill_code                varchar(50)   null,
    name                      varchar(255)  not null,
    description               text          null,
    business_type_id          int           null,
    default_required_level_id int           null,
    display_order             int default 0 null,
    job_type_id               int           null
);

create index idx_skills_business_type_id
    on plango.skills (business_type_id);

create index idx_skills_default_required_level_id
    on plango.skills (default_required_level_id);

create index idx_skills_job_type_id
    on plango.skills (job_type_id);

create table plango.solution_portal_categories
(
    id          int auto_increment
        primary key,
    name        varchar(255)                         not null,
    description text                                 null,
    sort_order  int        default 0                 not null,
    is_active   tinyint(1) default 1                 not null,
    created_at  timestamp  default CURRENT_TIMESTAMP not null,
    updated_at  timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create table plango.solution_portal_links
(
    id              int auto_increment
        primary key,
    category_id     int                                  not null,
    title           varchar(255)                         not null,
    url             text                                 not null,
    description     text                                 null,
    icon_type       varchar(50)                          not null,
    open_in_new_tab tinyint(1) default 1                 not null,
    visible_role    varchar(50)                          null,
    sort_order      int        default 0                 not null,
    is_active       tinyint(1) default 1                 not null,
    created_at      timestamp  default CURRENT_TIMESTAMP not null,
    updated_at      timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    click_count     int        default 0                 not null
);

create index idx_solution_portal_links_category_id
    on plango.solution_portal_links (category_id);

create table plango.solution_portal_stats
(
    page_name  varchar(100)  not null
        primary key,
    view_count int default 0 not null
);

create table ifs_reference_data.status_kind_table
(
    status_id   int      not null comment '汎用ステータスID'
        primary key,
    status_name char(50) null comment 'ステータス名称'
)
    comment '汎用状態定義テーブル';

create table plango.sub3_group_access
(
    id         int auto_increment
        primary key,
    sub3_id    varchar(3)   not null,
    group_name varchar(255) not null
);

create index idx_sub3_group_access_group_name
    on plango.sub3_group_access (group_name);

create index idx_sub3_group_access_sub3_id
    on plango.sub3_group_access (sub3_id);

create table plango.sub3_master
(
    sub3_id     varchar(3)                           not null
        primary key,
    name        varchar(100)                         not null,
    description text                                 null,
    active      tinyint(1) default 1                 not null,
    updated_at  datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create table project_hub.subproject_bind
(
    id           int  null,
    jrc_group_id int  null,
    variety      text null
);

create table plango.subproject_bind
(
    id           int auto_increment
        primary key,
    jrc_group_id int         not null comment 'グループID',
    variety      varchar(10) not null comment 'サブプロジェクト種別',
    constraint subproject_bind_group_kind_table_jrc_group_id_fk
        foreign key (jrc_group_id) references ifs_reference_data.group_kind_table (jrc_group_id)
);

create table plango.system_assignments
(
    id             int unsigned auto_increment
        primary key,
    system_id      int          null,
    group_name     varchar(255) null,
    role_id        int          null,
    employee_id    text         null,
    effective_from date         null,
    effective_to   date         null,
    note           text         null,
    created_at     datetime     null,
    updated_at     datetime     null,
    version_id     int          null
);

create table plango.system_groups
(
    id               int unsigned auto_increment
        primary key,
    name             text         null,
    owner_group_name varchar(255) null,
    description      text         null,
    display_order    int          null,
    is_active        tinyint(1)   null,
    created_at       datetime     null,
    updated_at       datetime     null
);

create table plango.system_manual_document_versions
(
    id            int unsigned auto_increment
        primary key,
    document_id   int                  null,
    version_no    int                  null,
    version_label text                 null,
    change_log    text                 null,
    file_path     text                 null,
    file_name     text                 null,
    mime_type     text                 null,
    file_size     int                  null,
    uploaded_by   text                 null,
    uploaded_at   datetime             null,
    is_deleted    tinyint(1) default 0 not null
);

create table plango.system_manual_documents
(
    id          int unsigned auto_increment
        primary key,
    title       text                                 null,
    description text                                 null,
    category    text                                 null,
    created_by  text                                 null,
    created_at  datetime   default CURRENT_TIMESTAMP not null,
    updated_by  text                                 null,
    updated_at  datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    is_deleted  tinyint(1) default 0                 not null
);

create table ifs_reference_data.system_processes_table
(
    process_id           int auto_increment comment 'プロセスID'
        primary key,
    process_ip_address   varchar(50) null comment '起動用IPアドレス',
    process_port_number  varchar(50) null comment '起動用ポート番号',
    process_name         varchar(50) null comment 'プロセス名称',
    process_alive_status tinyint(1)  null comment 'プロセス生存状態'
)
    comment '各マイクロサービスの起動情報設定テーブル';

create table plango.system_roles
(
    id            int unsigned auto_increment
        primary key,
    name          text null,
    display_order int  null,
    is_active     int  null
);

create table plango.system_versions
(
    id         int unsigned auto_increment
        primary key,
    title      text         null,
    group_name varchar(255) null,
    year       int          null,
    base_date  date         null,
    note       text         null,
    created_at datetime     null
);

create table plango.task_attachments
(
    id              int unsigned auto_increment
        primary key,
    task_id         int      null,
    filename        text     null,
    stored_filename text     null,
    file_size       int      null,
    file_path       text     null,
    uploaded_at     datetime null
);

create table plango.task_confirmations
(
    id           int unsigned auto_increment
        primary key,
    task_id      int        null,
    employee_id  text       null,
    confirmed    tinyint(1) null,
    confirmed_at datetime   null
);

create table project_hub.tasks
(
    task_id           int  null,
    unique_project_id text null,
    process_kind_id   int  null,
    task_name         text null,
    task_comment      text null,
    task_status       int  null,
    jrc_user_code     text null,
    dead_line         text null
);

create table plango.tasks
(
    task_id           int auto_increment comment 'タスクID'
        primary key,
    unique_project_id varchar(20)  not null comment 'プロジェクトID＋サブプロジェクトID',
    process_kind_id   varchar(255) not null comment '作業区分種別',
    task_name         varchar(20)  not null comment 'タスク名',
    task_comment      text         null comment 'タスクコメント',
    task_status       tinyint(1)   null comment 'タスク状態',
    jrc_user_code     varchar(10)  null comment '個人コード',
    dead_line         varchar(20)  null comment '期限'
)
    comment 'タスク管理テーブル';

create table plango.th_devices
(
    id            int unsigned auto_increment
        primary key,
    serial_number text null,
    name          text null,
    location      text null,
    enabled       int  null
);

create table plango.th_measurements
(
    id            int unsigned auto_increment
        primary key,
    device_id     int    null,
    timestamp     text   null,
    temperature_c double null,
    humidity_rh   double null
);

create table plango.todo_template_groups
(
    id          int auto_increment
        primary key,
    name        varchar(255)                         not null,
    description text                                 null,
    sort_order  int        default 0                 not null,
    is_active   tinyint(1) default 1                 not null,
    created_at  datetime   default CURRENT_TIMESTAMP not null,
    updated_at  datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create table plango.todo_templates
(
    id                   int unsigned auto_increment
        primary key,
    name                 text          null,
    group_id             int           null,
    description          text          null,
    default_priority     int           null,
    default_department   text          null,
    applicable_case_name text          null,
    sort_order           int default 0 null,
    is_active            tinyint(1)    null,
    created_at           datetime      null,
    updated_at           datetime      null
);

create index idx_todo_templates_group_id
    on plango.todo_templates (group_id);

create table plango.todos
(
    id                    int unsigned auto_increment
        primary key,
    project_id            int                           null,
    title                 text                          null,
    description           text                          null,
    priority              int                           null,
    due_date              date                          null,
    start_date            date                          null,
    progress              int                           null,
    department            text                          null,
    affiliation_category  text                          null,
    created_at            datetime                      null,
    updated_at            datetime                      null,
    created_by            text                          null,
    assigned_to           text                          null,
    attachment            text                          null,
    attachment_filename   text                          null,
    template_id           int                           null,
    status                varchar(20) default 'backlog' not null,
    no_deadline_mail      tinyint(1)  default 0         not null,
    deadline_notified_at  datetime                      null,
    deadline_notify_count int         default 0         not null,
    cc_assignees_json     text                          null
);

create index idx_todos_due_date
    on plango.todos (due_date);

create table plango.travel_costs
(
    id             bigint auto_increment
        primary key,
    expense_month  varchar(7)                         not null,
    project_id     varchar(50)                        not null,
    sub_project_id varchar(50)                        not null,
    amount_yen     bigint                             not null,
    created_at     datetime default CURRENT_TIMESTAMP not null,
    updated_at     datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create index idx_travel_costs_expense_month
    on plango.travel_costs (expense_month);

create index idx_travel_costs_project_id
    on plango.travel_costs (project_id);

create table ifs_reference_data.update_history
(
    id             int auto_increment
        primary key,
    process_id     int         not null comment 'プロセスID',
    process_name   varchar(20) null comment 'プロセス名称',
    update_date    datetime    null comment '更新日時',
    update_comment text        null comment '更新コメント'
)
    comment 'システム全体の変更履歴情報（公開用）';

create table project_hub.update_project_info
(
    id                 int  null,
    unique_project_id  text null,
    update_column_name text null,
    update_value       text null,
    update_date        text null,
    update_by          text null
);

create table plango.update_project_info
(
    id                 int auto_increment
        primary key,
    unique_project_id  varchar(20)  not null comment 'プロジェクトID＋サブプロジェクトID',
    update_column_name varchar(99)  not null comment '更新対象列名',
    update_value       varchar(999) not null comment '更新値',
    update_date        datetime     not null comment '更新日時',
    update_by          varchar(10)  not null comment '個人コード（更新者）'
)
    comment 'ProjectHub側で入力された更新情報記録テーブル';

create table plango.usage_format_placeholders
(
    id            int auto_increment
        primary key,
    template_id   int                                not null,
    placeholder   varchar(100)                       not null,
    source_type   enum ('header', 'item', 'static')  not null,
    source_column varchar(100)                       null,
    note          text                               null,
    created_at    datetime default CURRENT_TIMESTAMP not null,
    updated_at    datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create index idx_usage_format_placeholders_template_id
    on plango.usage_format_placeholders (template_id);

create table plango.usage_format_templates
(
    id               int auto_increment
        primary key,
    name             varchar(100)                           not null,
    code             varchar(50)                            not null,
    file_type        enum ('excel', 'word')                 not null,
    language         enum ('ja', 'en')                      not null,
    description      text                                   null,
    file_path        varchar(255)                           not null,
    placeholder_type enum ('usage_list', 'instrument_list') not null,
    active           tinyint(1) default 1                   not null,
    created_at       datetime   default CURRENT_TIMESTAMP   not null,
    updated_at       datetime   default CURRENT_TIMESTAMP   not null on update CURRENT_TIMESTAMP,
    constraint uq_usage_format_templates_code
        unique (code)
);

create table plango.user_affiliation_histories
(
    id                   bigint auto_increment
        primary key,
    employee_id          varchar(50)                         not null,
    company_name         varchar(255)                        null,
    department_name      varchar(255)                        null,
    business_unit        varchar(255)                        null,
    affiliation_category varchar(255)                        null,
    group_name           varchar(255)                        null,
    group_code           varchar(100)                        null,
    department_id        varchar(100)                        null,
    start_at             datetime                            not null,
    end_at               datetime                            null,
    created_at           timestamp default CURRENT_TIMESTAMP null
);

create index idx_user_affiliation_histories_employee_id
    on plango.user_affiliation_histories (employee_id);

create index idx_user_affiliation_histories_group_code
    on plango.user_affiliation_histories (group_code);

create index idx_user_affiliation_histories_group_name
    on plango.user_affiliation_histories (group_name);

create table ifs_reference_data.user_auth_level_table
(
    jrc_user_code varchar(10) not null comment '個人コード'
        primary key,
    system_admin  tinyint(1)  not null comment 'システム管理ユーザー',
    admin         tinyint(1)  null comment '管理ユーザー',
    standard      tinyint(1)  not null comment '標準ユーザー',
    guest         tinyint(1)  not null comment 'ゲストユーザー'
)
    comment 'ユーザー権限設定テーブル';

create table plango.user_job_types
(
    id          int auto_increment
        primary key,
    employee_id varchar(32)          not null,
    job_type_id int                  not null,
    is_primary  tinyint(1) default 0 null
);

create index idx_user_job_types_employee_id
    on plango.user_job_types (employee_id);

create index idx_user_job_types_job_type_id
    on plango.user_job_types (job_type_id);

create table plango.user_requests
(
    id                   bigint unsigned auto_increment
        primary key,
    employee_id          varchar(32)                           not null,
    user_name            varchar(255)                          not null,
    user_email           varchar(255)                          null,
    company_name         varchar(255)                          null,
    business_unit        varchar(255)                          null,
    department_name      varchar(255)                          null,
    affiliation_category varchar(255)                          null,
    group_name           varchar(255)                          not null,
    comment              text                                  null,
    requester_name       varchar(255)                          not null,
    requester_email      varchar(255)                          not null,
    status               varchar(20) default 'pending'         not null,
    created_at           datetime    default CURRENT_TIMESTAMP not null,
    updated_at           datetime    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    processed_by         varchar(32)                           null,
    processed_at         datetime                              null,
    reject_reason        text                                  null
);

create index idx_user_requests_employee_id
    on plango.user_requests (employee_id);

create index idx_user_requests_status
    on plango.user_requests (status);

create table plango.user_skill_history
(
    id          bigint auto_increment
        primary key,
    employee_id varchar(20)                                        not null,
    skill_id    int                                                not null,
    level_id    int                                                null,
    changed_by  varchar(20)                                        not null,
    change_type enum ('self', 'manager') default 'self'            not null,
    changed_at  datetime                 default CURRENT_TIMESTAMP not null,
    batch_id    bigint                                             null
);

create index idx_user_skill_history_batch_id
    on plango.user_skill_history (batch_id);

create index idx_user_skill_history_employee_id
    on plango.user_skill_history (employee_id);

create index idx_user_skill_history_skill_id
    on plango.user_skill_history (skill_id);

create table plango.user_skill_self_batches
(
    id          bigint auto_increment
        primary key,
    employee_id varchar(20)                        not null,
    saved_at    datetime default CURRENT_TIMESTAMP not null
);

create index idx_user_skill_self_batches_employee_id
    on plango.user_skill_self_batches (employee_id);

create table plango.user_skills
(
    id                   int auto_increment
        primary key,
    employee_id          varchar(32) not null,
    skill_id             int         not null,
    self_level_id        int         null,
    manager_level_id     int         null,
    self_updated_at      datetime    null,
    manager_updated_at   datetime    null,
    manager_evaluator_id varchar(32) null,
    comment              text        null
);

create index idx_user_skills_employee_id
    on plango.user_skills (employee_id);

create index idx_user_skills_manager_level_id
    on plango.user_skills (manager_level_id);

create index idx_user_skills_self_level_id
    on plango.user_skills (self_level_id);

create index idx_user_skills_skill_id
    on plango.user_skills (skill_id);

create table plango.users
(
    employee_id                 varchar(32)          not null
        primary key,
    password                    text                 null,
    is_admin                    tinyint(1)           null,
    name                        text                 null,
    group_name                  text                 null,
    group_code                  text                 null,
    department_id               text                 null,
    email                       text                 null,
    role                        text                 null,
    is_overtime_approver        tinyint(1)           null,
    is_first_login              tinyint(1)           null,
    login_count                 int                  null,
    last_login_at               datetime             null,
    is_overtime_viewer          tinyint(1)           null,
    internal_phone              text                 null,
    external_phone              text                 null,
    internal_fax                text                 null,
    external_fax                text                 null,
    internal_mobile             text                 null,
    external_mobile             text                 null,
    company_name                text                 null,
    department_name             text                 null,
    business_unit               text                 null,
    is_duty_manager             tinyint(1)           null,
    affiliation_category        text                 null,
    is_active                   tinyint(1) default 1 not null,
    is_consumables_manager      tinyint(1)           null,
    is_effort_manager           tinyint(1) default 0 null,
    is_skillmap_manager         tinyint(1) default 0 not null,
    is_qa_manager               tinyint(1) default 0 null,
    is_notice_manager           tinyint(1) default 0 not null,
    is_solution_portal_manager  tinyint(1) default 0 not null,
    is_subid_manager            tinyint(1) default 0 not null,
    is_rate_manager             tinyint(1) default 0 not null,
    is_weekly_report_manager    tinyint(1) default 0 not null,
    is_company_calendar_manager tinyint(1) default 0 not null,
    is_user_manager             tinyint(1) default 0 not null,
    is_group_docs_manager       tinyint(1) default 0 not null,
    is_manual_docs_manager      tinyint(1) default 0 not null,
    is_system_video_manager     tinyint(1) default 0 not null
);

create table plango.videos
(
    id             int unsigned auto_increment
        primary key,
    title          text        null,
    description    text        null,
    category       text        null,
    filename       text        null,
    upload_date    datetime    null,
    status         text        null,
    created_by     varchar(32) null,
    view_count     int         null,
    last_viewed_at datetime    null,
    updated_at     datetime    null,
    file_deleted   tinyint(1)  null
);

create table plango.view_history
(
    id                int unsigned auto_increment
        primary key,
    user_id           varchar(32) null,
    video_id          int         null,
    viewed_at         datetime    null,
    view_duration     int         null,
    completion_status text        null
);

create table plango.witness_result_files
(
    id               bigint auto_increment
        primary key,
    project_id       varchar(50)                        not null,
    sub_project_id   varchar(50)                        null,
    witness_no       int                                not null,
    file_name_orig   varchar(255)                       not null,
    file_name_saved  varchar(255)                       not null,
    file_path        varchar(512)                       not null,
    file_size        bigint                             null,
    content_type     varchar(100)                       null,
    comment          varchar(500)                       null,
    uploaded_at      datetime default CURRENT_TIMESTAMP not null,
    uploaded_by_name varchar(100)                       null,
    uploaded_by_emp  varchar(20)                        null
);

create index idx_witness_result_files_project_id
    on plango.witness_result_files (project_id);

create table plango.work_hour_rates
(
    id         bigint auto_increment
        primary key,
    year       int                                 not null,
    month      tinyint                             not null,
    group_name varchar(255)                        not null,
    rate       decimal(10, 2)                      not null,
    note       varchar(255)                        null,
    updated_at timestamp default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP
);

create index idx_work_hour_rates_year
    on plango.work_hour_rates (year);

create table ifs_reference_data.work_item_kind_table
(
    id          int auto_increment comment '自動生成の一意のID'
        primary key,
    item_number varchar(10) not null comment '作業種別番号',
    item_name   varchar(50) not null comment '作業種別名'
)
    comment '作業種別マスタ';

create table plango.work_raw_actuals
(
    id              bigint auto_increment
        primary key,
    status          varchar(20)                         null,
    work_date       date                                null,
    employee_no     varchar(20)                         null,
    employee_name   varchar(50)                         null,
    employee_type   varchar(20)                         null,
    start_time      varchar(10)                         null,
    end_time        varchar(10)                         null,
    work_hours      decimal(6, 2)                       null,
    mf_order        varchar(50)                         null,
    order_no        varchar(50)                         null,
    product_name    varchar(100)                        null,
    work_code       varchar(20)                         null,
    work_name       varchar(100)                        null,
    customer_code   varchar(50)                         null,
    customer_name   varchar(100)                        null,
    manage_type     varchar(50)                         null,
    remarks         text                                null,
    board_name      varchar(100)                        null,
    idle_flag       varchar(50)                         null,
    support_section varchar(100)                        null,
    approver        varchar(50)                         null,
    approve_date    varchar(20)                         null,
    approve_time    varchar(20)                         null,
    model_type      varchar(50)                         null,
    business_type   varchar(50)                         null,
    created_at      timestamp default CURRENT_TIMESTAMP null
);

create table plango.work_raw_actuals_import_logs
(
    id            bigint unsigned auto_increment
        primary key,
    file_path     varchar(512)  not null,
    file_mtime    datetime      not null,
    imported_at   datetime      not null,
    rows_inserted int default 0 not null,
    status        varchar(16)   not null,
    message       text          null,
    trigger_type  varchar(16)   not null
);

create index idx_work_raw_actuals_import_logs_file_path
    on plango.work_raw_actuals_import_logs (file_path);

create index idx_work_raw_actuals_import_logs_imported_at
    on plango.work_raw_actuals_import_logs (imported_at);

create table ifs_reference_data.work_time_record_table
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

create definer = dbuser@`%` view ifs_reference_data.test_view as
select `i`.`unique_project_id`                                                                                     AS `unique_project_id`,
       coalesce(`ifs_reference_data`.`u`.`project_id`, `i`.`project_id`)                                           AS `project_id`,
       coalesce(`ifs_reference_data`.`u`.`sub_project_id`,
                `i`.`sub_project_id`)                                                                              AS `sub_project_id`,
       coalesce(`ifs_reference_data`.`u`.`sub_project_name`,
                `i`.`sub_project_name`)                                                                            AS `sub_project_name`,
       coalesce(`ifs_reference_data`.`u`.`department`, `i`.`department`)                                           AS `department`,
       coalesce(`ifs_reference_data`.`u`.`parent_sub_project_id`,
                `i`.`parent_sub_project_id`)                                                                       AS `parent_sub_project_id`,
       coalesce(`ifs_reference_data`.`u`.`variety`, `i`.`variety`)                                                 AS `variety`,
       coalesce(`ifs_reference_data`.`u`.`sub_project_amount`,
                `i`.`sub_project_amount`)                                                                          AS `sub_project_amount`,
       coalesce(`ifs_reference_data`.`u`.`sub_project_cost`,
                `i`.`sub_project_cost`)                                                                            AS `sub_project_cost`,
       coalesce(`ifs_reference_data`.`u`.`completion_request_date`,
                `i`.`completion_request_date`)                                                                     AS `completion_request_date`,
       coalesce(`ifs_reference_data`.`u`.`completion_request`,
                `i`.`completion_request`)                                                                          AS `completion_request`,
       coalesce(`ifs_reference_data`.`u`.`status`, `i`.`status`)                                                   AS `status`,
       coalesce(`ifs_reference_data`.`u`.`variety_name`,
                `i`.`variety_name`)                                                                                AS `variety_name`,
       coalesce(`ifs_reference_data`.`u`.`project_name`,
                `i`.`project_name`)                                                                                AS `project_name`,
       coalesce(`ifs_reference_data`.`u`.`accounting_completed`,
                `i`.`accounting_completed`)                                                                        AS `accounting_completed`,
       coalesce(`ifs_reference_data`.`u`.`completion_date`,
                `i`.`completion_date`)                                                                             AS `completion_date`,
       coalesce(`ifs_reference_data`.`u`.`initial_completion_date`,
                `i`.`initial_completion_date`)                                                                     AS `initial_completion_date`,
       coalesce(`ifs_reference_data`.`u`.`inspection_preparation_start_date`,
                `b`.`inspection_preparation_start_date`)                                                           AS `inspection_preparation_start_date`,
       coalesce(`ifs_reference_data`.`u`.`inspection_preparation_end_date`,
                `b`.`inspection_preparation_end_date`)                                                             AS `inspection_preparation_end_date`,
       coalesce(`ifs_reference_data`.`u`.`inspection_start_date`,
                `b`.`inspection_start_date`)                                                                       AS `inspection_start_date`,
       coalesce(`ifs_reference_data`.`u`.`inspection_end_date`,
                `b`.`inspection_end_date`)                                                                         AS `inspection_end_date`,
       coalesce(`ifs_reference_data`.`u`.`inspection_meeting_preparation_start_date`,
                `b`.`inspection_meeting_preparation_start_date`)                                                   AS `inspection_meeting_preparation_start_date`,
       coalesce(`ifs_reference_data`.`u`.`inspection_meeting_preparation_end_date`,
                `b`.`inspection_meeting_preparation_end_date`)                                                     AS `inspection_meeting_preparation_end_date`,
       coalesce(`ifs_reference_data`.`u`.`inspection_meeting_start_date`,
                `b`.`inspection_meeting_start_date`)                                                               AS `inspection_meeting_start_date`,
       coalesce(`ifs_reference_data`.`u`.`inspection_meeting_end_date`,
                `b`.`inspection_meeting_end_date`)                                                                 AS `inspection_meeting_end_date`,
       coalesce(`ifs_reference_data`.`u`.`shipping_preparation_start_date`,
                `b`.`shipping_preparation_start_date`)                                                             AS `shipping_preparation_start_date`,
       coalesce(`ifs_reference_data`.`u`.`shipping_preparation_end_date`,
                `b`.`shipping_preparation_end_date`)                                                               AS `shipping_preparation_end_date`,
       coalesce(`ifs_reference_data`.`u`.`shipping_start_date`,
                `b`.`shipping_start_date`)                                                                         AS `shipping_start_date`,
       coalesce(`ifs_reference_data`.`u`.`shipping_end_date`,
                `b`.`shipping_end_date`)                                                                           AS `shipping_end_date`,
       coalesce(`ifs_reference_data`.`u`.`client_name`, `p`.`client_name`)                                         AS `client_name`,
       coalesce(`ifs_reference_data`.`u`.`contract_deadline`,
                `p`.`contract_deadline`)                                                                           AS `contract_deadline`,
       coalesce(`ifs_reference_data`.`u`.`shipping_approval_date`,
                `p`.`shipping_approval_date`)                                                                      AS `shipping_approval_date`,
       coalesce(`ifs_reference_data`.`u`.`progress`, `p`.`progress`)                                               AS `progress`,
       coalesce(`ifs_reference_data`.`u`.`area_used`, `p`.`area_used`)                                             AS `area_used`,
       coalesce(`ifs_reference_data`.`u`.`deployment_location`,
                `p`.`deployment_location`)                                                                         AS `deployment_location`,
       coalesce(`ifs_reference_data`.`u`.`business_trip_start_date`,
                `p`.`business_trip_start_date`)                                                                    AS `business_trip_start_date`,
       coalesce(`ifs_reference_data`.`u`.`business_trip_end_date`,
                `p`.`business_trip_end_date`)                                                                      AS `business_trip_end_date`,
       coalesce(`ifs_reference_data`.`u`.`technical_manager`,
                `p`.`technical_manager`)                                                                           AS `technical_manager`,
       coalesce(`ifs_reference_data`.`u`.`admin_manager`,
                `p`.`admin_manager`)                                                                               AS `admin_manager`,
       coalesce(`ifs_reference_data`.`u`.`person_in_charge`,
                `p`.`person_in_charge`)                                                                            AS `person_in_charge`,
       coalesce(`ifs_reference_data`.`u`.`worker`, `p`.`worker`)                                                   AS `worker`,
       coalesce(`ifs_reference_data`.`u`.`support_staff`,
                `p`.`support_staff`)                                                                               AS `support_staff`,
       coalesce(`ifs_reference_data`.`u`.`case_name`, `p`.`case_name`)                                             AS `case_name`,
       coalesce(`ifs_reference_data`.`u`.`man_hours`, `p`.`man_hours`)                                             AS `man_hours`,
       coalesce(`ifs_reference_data`.`u`.`used_man_hours`,
                `p`.`used_man_hours`)                                                                              AS `used_man_hours`,
       coalesce(`ifs_reference_data`.`u`.`comment`, `p`.`comment`)                                                 AS `comment`,
       coalesce(`ifs_reference_data`.`u`.`components_list_date`,
                `d`.`components_list_date`)                                                                        AS `components_list_date`,
       coalesce(`ifs_reference_data`.`u`.`drawing_release_date`,
                `d`.`drawing_release_date`)                                                                        AS `drawing_release_date`,
       coalesce(`ifs_reference_data`.`u`.`inspection_guideline_date`,
                `d`.`inspection_guideline_date`)                                                                   AS `inspection_guideline_date`,
       coalesce(`ifs_reference_data`.`u`.`dr_date`, `d`.`dr_date`)                                                 AS `dr_date`,
       coalesce(`ifs_reference_data`.`u`.`dve_date`, `d`.`dve_date`)                                               AS `dve_date`,
       coalesce(`ifs_reference_data`.`u`.`incoming_inspection_date`,
                `d`.`incoming_inspection_date`)                                                                    AS `incoming_inspection_date`,
       coalesce(`ifs_reference_data`.`u`.`inspection_meeting_date`,
                `d`.`inspection_meeting_date`)                                                                     AS `inspection_meeting_date`,
       coalesce(`ifs_reference_data`.`u`.`dva_date`, `d`.`dva_date`)                                               AS `dva_date`,
       coalesce(`ifs_reference_data`.`u`.`ship_date`, `d`.`ship_date`)                                             AS `ship_date`,
       coalesce(`ifs_reference_data`.`u`.`completion_documents_date`,
                `d`.`completion_documents_date`)                                                                   AS `completion_documents_date`,
       coalesce(`ifs_reference_data`.`u`.`years`, `d`.`years`)                                                     AS `years`,
       coalesce(`ifs_reference_data`.`u`.`jrc_user_code`,
                `a`.`jrc_user_code`)                                                                               AS `jrc_user_code`,
       coalesce(`ifs_reference_data`.`u`.`inspection_ready`,
                `a`.`inspection_ready`)                                                                            AS `inspection_ready`,
       coalesce(`ifs_reference_data`.`u`.`complete`, `c`.`complete`)                                               AS `complete`,
       coalesce(`ifs_reference_data`.`u`.`se_comment`,
                `comment`.`se_comment`)                                                                            AS `se_comment`,
       coalesce(`ifs_reference_data`.`u`.`ig_comment`,
                `comment`.`ig_comment`)                                                                            AS `ig_comment`,
       coalesce(`ifs_reference_data`.`u`.`partial_ship_date_1`,
                `partial_ship`.`partial_ship_date_1`)                                                              AS `partial_ship_date_1`,
       coalesce(`ifs_reference_data`.`u`.`partial_ship_date_2`,
                `partial_ship`.`partial_ship_date_2`)                                                              AS `partial_ship_date_2`,
       coalesce(`ifs_reference_data`.`u`.`partial_ship_date_3`,
                `partial_ship`.`partial_ship_date_3`)                                                              AS `partial_ship_date_3`,
       coalesce(`ifs_reference_data`.`u`.`partial_ship_date_4`,
                `partial_ship`.`partial_ship_date_4`)                                                              AS `partial_ship_date_4`,
       coalesce(`ifs_reference_data`.`u`.`partial_ship_date_5`,
                `partial_ship`.`partial_ship_date_5`)                                                              AS `partial_ship_date_5`,
       coalesce(`ifs_reference_data`.`u`.`partial_ship_date_6`,
                `partial_ship`.`partial_ship_date_6`)                                                              AS `partial_ship_date_6`,
       coalesce(`ifs_reference_data`.`u`.`partial_ship_date_7`,
                `partial_ship`.`partial_ship_date_7`)                                                              AS `partial_ship_date_7`,
       coalesce(`ifs_reference_data`.`u`.`partial_ship_date_8`,
                `partial_ship`.`partial_ship_date_8`)                                                              AS `partial_ship_date_8`,
       coalesce(`ifs_reference_data`.`u`.`partial_ship_date_9`,
                `partial_ship`.`partial_ship_date_9`)                                                              AS `partial_ship_date_9`,
       (select `ifs_reference_data`.`jrc_users_table`.`jrc_user_name`
        from `ifs_reference_data`.`jrc_users_table`
        where (`ifs_reference_data`.`jrc_users_table`.`jrc_user_code` =
               `a`.`jrc_user_code`))                                                                               AS `responsible`,
       (select (sum((unix_timestamp(`ifs_reference_data`.`work_time_record_table`.`end_date`) -
                     unix_timestamp(`ifs_reference_data`.`work_time_record_table`.`start_date`))) / 3600)
        from `ifs_reference_data`.`work_time_record_table`
        where (`ifs_reference_data`.`work_time_record_table`.`unique_project_id` =
               `i`.`unique_project_id`))                                                                           AS `sum_man_hours`
from ((((((((`ifs_reference_data`.`ifs_projects_table` `i` left join `ifs_reference_data`.`update_project_latest_view` `u`
             on ((`i`.`unique_project_id` = `ifs_reference_data`.`u`.`unique_project_id`))) left join `ifs_reference_data`.`backlog_task_date_table` `b`
            on ((`i`.`unique_project_id` = `b`.`unique_project_id`))) left join `plango`.`project_management` `p`
           on ((`i`.`unique_project_id` = `p`.`unique_project_id`))) left join `ifs_reference_data`.`design_plan_table` `d`
          on ((`i`.`unique_project_id` = `d`.`unique_project_id`))) left join `ifs_reference_data`.`project_assign_table` `a`
         on ((`i`.`unique_project_id` = `a`.`unique_project_id`))) left join `plango`.`completed_projects` `c`
        on ((`i`.`unique_project_id` = `c`.`unique_project_id`))) left join `plango`.`comments` `comment`
       on ((`i`.`unique_project_id` = `comment`.`unique_project_id`))) left join `plango`.`partial_shipment` `partial_ship`
      on ((`i`.`unique_project_id` = `partial_ship`.`unique_project_id`)))
where (`i`.`status` = '未完了');

-- comment on column ifs_reference_data.test_view.unique_project_id not supported: ユニークプロジェクトID

create definer = dbuser@`%` view ifs_reference_data.update_project_latest_view as
select `upi`.`unique_project_id`                                                                                      AS `unique_project_id`,
       max((case
                when (`upi`.`update_column_name` = 'project_id')
                    then `upi`.`update_value` end))                                                                   AS `project_id`,
       max((case
                when (`upi`.`update_column_name` = 'sub_project_id')
                    then `upi`.`update_value` end))                                                                   AS `sub_project_id`,
       max((case
                when (`upi`.`update_column_name` = 'sub_project_name')
                    then `upi`.`update_value` end))                                                                   AS `sub_project_name`,
       max((case
                when (`upi`.`update_column_name` = 'department')
                    then `upi`.`update_value` end))                                                                   AS `department`,
       max((case
                when (`upi`.`update_column_name` = 'parent_sub_project_id')
                    then `upi`.`update_value` end))                                                                   AS `parent_sub_project_id`,
       max((case
                when (`upi`.`update_column_name` = 'variety')
                    then `upi`.`update_value` end))                                                                   AS `variety`,
       max((case
                when (`upi`.`update_column_name` = 'sub_project_amount')
                    then `upi`.`update_value` end))                                                                   AS `sub_project_amount`,
       max((case
                when (`upi`.`update_column_name` = 'sub_project_cost')
                    then `upi`.`update_value` end))                                                                   AS `sub_project_cost`,
       max((case
                when (`upi`.`update_column_name` = 'completion_request_date')
                    then `upi`.`update_value` end))                                                                   AS `completion_request_date`,
       max((case
                when (`upi`.`update_column_name` = 'completion_request')
                    then `upi`.`update_value` end))                                                                   AS `completion_request`,
       max((case
                when (`upi`.`update_column_name` = 'status')
                    then `upi`.`update_value` end))                                                                   AS `status`,
       max((case
                when (`upi`.`update_column_name` = 'variety_name')
                    then `upi`.`update_value` end))                                                                   AS `variety_name`,
       max((case
                when (`upi`.`update_column_name` = 'project_name')
                    then `upi`.`update_value` end))                                                                   AS `project_name`,
       max((case
                when (`upi`.`update_column_name` = 'accounting_completed')
                    then `upi`.`update_value` end))                                                                   AS `accounting_completed`,
       max((case
                when (`upi`.`update_column_name` = 'completion_date')
                    then `upi`.`update_value` end))                                                                   AS `completion_date`,
       max((case
                when (`upi`.`update_column_name` = 'initial_completion_date')
                    then `upi`.`update_value` end))                                                                   AS `initial_completion_date`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_preparation_start_date')
                    then `upi`.`update_value` end))                                                                   AS `inspection_preparation_start_date`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_preparation_end_date')
                    then `upi`.`update_value` end))                                                                   AS `inspection_preparation_end_date`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_start_date')
                    then `upi`.`update_value` end))                                                                   AS `inspection_start_date`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_end_date')
                    then `upi`.`update_value` end))                                                                   AS `inspection_end_date`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_meeting_preparation_start_date')
                    then `upi`.`update_value` end))                                                                   AS `inspection_meeting_preparation_start_date`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_meeting_preparation_end_date')
                    then `upi`.`update_value` end))                                                                   AS `inspection_meeting_preparation_end_date`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_meeting_start_date')
                    then `upi`.`update_value` end))                                                                   AS `inspection_meeting_start_date`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_meeting_end_date')
                    then `upi`.`update_value` end))                                                                   AS `inspection_meeting_end_date`,
       max((case
                when (`upi`.`update_column_name` = 'shipping_preparation_start_date')
                    then `upi`.`update_value` end))                                                                   AS `shipping_preparation_start_date`,
       max((case
                when (`upi`.`update_column_name` = 'shipping_preparation_end_date')
                    then `upi`.`update_value` end))                                                                   AS `shipping_preparation_end_date`,
       max((case
                when (`upi`.`update_column_name` = 'shipping_start_date')
                    then `upi`.`update_value` end))                                                                   AS `shipping_start_date`,
       max((case
                when (`upi`.`update_column_name` = 'shipping_end_date')
                    then `upi`.`update_value` end))                                                                   AS `shipping_end_date`,
       max((case
                when (`upi`.`update_column_name` = 'client_name')
                    then `upi`.`update_value` end))                                                                   AS `client_name`,
       max((case
                when (`upi`.`update_column_name` = 'contract_deadline')
                    then `upi`.`update_value` end))                                                                   AS `contract_deadline`,
       max((case
                when (`upi`.`update_column_name` = 'shipping_approval_date')
                    then `upi`.`update_value` end))                                                                   AS `shipping_approval_date`,
       max((case
                when (`upi`.`update_column_name` = 'progress')
                    then `upi`.`update_value` end))                                                                   AS `progress`,
       max((case
                when (`upi`.`update_column_name` = 'area_used')
                    then `upi`.`update_value` end))                                                                   AS `area_used`,
       max((case
                when (`upi`.`update_column_name` = 'deployment_location')
                    then `upi`.`update_value` end))                                                                   AS `deployment_location`,
       max((case
                when (`upi`.`update_column_name` = 'business_trip_start_date')
                    then `upi`.`update_value` end))                                                                   AS `business_trip_start_date`,
       max((case
                when (`upi`.`update_column_name` = 'business_trip_end_date')
                    then `upi`.`update_value` end))                                                                   AS `business_trip_end_date`,
       max((case
                when (`upi`.`update_column_name` = 'technical_manager')
                    then `upi`.`update_value` end))                                                                   AS `technical_manager`,
       max((case
                when (`upi`.`update_column_name` = 'admin_manager')
                    then `upi`.`update_value` end))                                                                   AS `admin_manager`,
       max((case
                when (`upi`.`update_column_name` = 'person_in_charge')
                    then `upi`.`update_value` end))                                                                   AS `person_in_charge`,
       max((case
                when (`upi`.`update_column_name` = 'worker')
                    then `upi`.`update_value` end))                                                                   AS `worker`,
       max((case
                when (`upi`.`update_column_name` = 'support_staff')
                    then `upi`.`update_value` end))                                                                   AS `support_staff`,
       max((case
                when (`upi`.`update_column_name` = 'case_name')
                    then `upi`.`update_value` end))                                                                   AS `case_name`,
       max((case
                when (`upi`.`update_column_name` = 'man_hours')
                    then `upi`.`update_value` end))                                                                   AS `man_hours`,
       max((case
                when (`upi`.`update_column_name` = 'used_man_hours')
                    then `upi`.`update_value` end))                                                                   AS `used_man_hours`,
       max((case
                when (`upi`.`update_column_name` = 'comment')
                    then `upi`.`update_value` end))                                                                   AS `comment`,
       max((case
                when (`upi`.`update_column_name` = 'components_list_date')
                    then `upi`.`update_value` end))                                                                   AS `components_list_date`,
       max((case
                when (`upi`.`update_column_name` = 'drawing_release_date')
                    then `upi`.`update_value` end))                                                                   AS `drawing_release_date`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_guideline_date')
                    then `upi`.`update_value` end))                                                                   AS `inspection_guideline_date`,
       max((case
                when (`upi`.`update_column_name` = 'dr_date')
                    then `upi`.`update_value` end))                                                                   AS `dr_date`,
       max((case
                when (`upi`.`update_column_name` = 'dve_date')
                    then `upi`.`update_value` end))                                                                   AS `dve_date`,
       max((case
                when (`upi`.`update_column_name` = 'incoming_inspection_date')
                    then `upi`.`update_value` end))                                                                   AS `incoming_inspection_date`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_meeting_date')
                    then `upi`.`update_value` end))                                                                   AS `inspection_meeting_date`,
       max((case
                when (`upi`.`update_column_name` = 'dva_date')
                    then `upi`.`update_value` end))                                                                   AS `dva_date`,
       max((case
                when (`upi`.`update_column_name` = 'ship_date')
                    then `upi`.`update_value` end))                                                                   AS `ship_date`,
       max((case
                when (`upi`.`update_column_name` = 'completion_documents_date')
                    then `upi`.`update_value` end))                                                                   AS `completion_documents_date`,
       max((case
                when (`upi`.`update_column_name` = 'years')
                    then `upi`.`update_value` end))                                                                   AS `years`,
       max((case
                when (`upi`.`update_column_name` = 'jrc_user_code')
                    then `upi`.`update_value` end))                                                                   AS `jrc_user_code`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_ready')
                    then `upi`.`update_value` end))                                                                   AS `inspection_ready`,
       max((case
                when (`upi`.`update_column_name` = 'complete')
                    then `upi`.`update_value` end))                                                                   AS `complete`,
       max((case
                when (`upi`.`update_column_name` = 'se_comment')
                    then `upi`.`update_value` end))                                                                   AS `se_comment`,
       max((case
                when (`upi`.`update_column_name` = 'ig_comment')
                    then `upi`.`update_value` end))                                                                   AS `ig_comment`,
       max((case
                when (`upi`.`update_column_name` = 'partial_ship_date_1')
                    then `upi`.`update_value` end))                                                                   AS `partial_ship_date_1`,
       max((case
                when (`upi`.`update_column_name` = 'partial_ship_date_2')
                    then `upi`.`update_value` end))                                                                   AS `partial_ship_date_2`,
       max((case
                when (`upi`.`update_column_name` = 'partial_ship_date_3')
                    then `upi`.`update_value` end))                                                                   AS `partial_ship_date_3`,
       max((case
                when (`upi`.`update_column_name` = 'partial_ship_date_4')
                    then `upi`.`update_value` end))                                                                   AS `partial_ship_date_4`,
       max((case
                when (`upi`.`update_column_name` = 'partial_ship_date_5')
                    then `upi`.`update_value` end))                                                                   AS `partial_ship_date_5`,
       max((case
                when (`upi`.`update_column_name` = 'partial_ship_date_6')
                    then `upi`.`update_value` end))                                                                   AS `partial_ship_date_6`,
       max((case
                when (`upi`.`update_column_name` = 'partial_ship_date_7')
                    then `upi`.`update_value` end))                                                                   AS `partial_ship_date_7`,
       max((case
                when (`upi`.`update_column_name` = 'partial_ship_date_8')
                    then `upi`.`update_value` end))                                                                   AS `partial_ship_date_8`,
       max((case
                when (`upi`.`update_column_name` = 'partial_ship_date_9')
                    then `upi`.`update_value` end))                                                                   AS `partial_ship_date_9`
from `plango`.`update_project_info` `upi`
where `upi`.`update_date` in (select max(`plango`.`update_project_info`.`update_date`)
                              from `plango`.`update_project_info`
                              where ((`plango`.`update_project_info`.`update_column_name` =
                                      `upi`.`update_column_name`) and
                                     (`plango`.`update_project_info`.`unique_project_id` = `upi`.`unique_project_id`)))
group by `upi`.`unique_project_id`;

-- comment on column ifs_reference_data.update_project_latest_view.unique_project_id not supported: プロジェクトID＋サブプロジェクトID

