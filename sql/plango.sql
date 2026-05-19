create table active_sessions
(
    session_id    varchar(255)                        not null
        primary key,
    user_id       varchar(255)                        not null,
    last_activity timestamp default CURRENT_TIMESTAMP null
);

create table affiliation_categories
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

create table area_capacities
(
    area                   varchar(100)         not null
        primary key,
    max_area               double               null,
    is_active              tinyint(1) default 1 not null,
    include_in_aggregation tinyint(1) default 1 not null
);

create table attendance_board_members
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
    on attendance_board_members (board_id);

create index idx_attendance_board_members_employee_id
    on attendance_board_members (employee_id);

create table attendance_boards
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
    on attendance_boards (group_name);

create table attendance_status_master
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

create table attendance_statuses
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
    on attendance_statuses (board_id);

create index idx_attendance_statuses_employee_id
    on attendance_statuses (employee_id);

create index idx_attendance_statuses_status_code
    on attendance_statuses (status_code);

create table board_attachments
(
    id              int unsigned auto_increment
        primary key,
    post_id         int      null,
    filename        text     null,
    stored_filename text     null,
    file_size       int      null,
    uploaded_at     datetime null
);

create table board_posts
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

create table categories
(
    id          int unsigned auto_increment
        primary key,
    name        text null,
    description text null
);

create table comments
(
    unique_project_id varchar(20)   not null
        primary key,
    se_comment        varchar(999)  null,
    ig_comment        varchar(8999) null
);

create table company_calendar
(
    date        date       not null
        primary key,
    is_holiday  tinyint(1) null,
    description text       null
);

create table completed_projects
(
    unique_project_id varchar(20) not null
        primary key,
    complete          tinyint(1)  not null
);

create table completed_todos
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

create table consumables_items
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

create table consumables_request_details
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

create table consumables_request_headers
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

create table duty_item_answer_files
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

create table duty_item_task_files
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

create table duty_items
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

create table duty_monthly_assignments
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
    on duty_monthly_assignments (group_name);

create table equipment
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

create table equipment_categories
(
    id          int unsigned auto_increment
        primary key,
    name        text null,
    description text null
);

create table equipment_permissions
(
    id           int unsigned auto_increment
        primary key,
    equipment_id int      null,
    role         text     null,
    created_at   datetime null
);

create table equipment_reservation_series
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

create table equipment_reservations
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

create table estimate_pdfs
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
    on estimate_pdfs (pjid);

create table gantt_details
(
    id                int auto_increment
        primary key,
    unique_project_id varchar(20) not null,
    process_kind_id   int         not null,
    detail_comment    mediumtext  null,
    update_by         varchar(10) not null,
    update_date       varchar(30) not null
);

create table group_board_attachments
(
    id              int unsigned auto_increment
        primary key,
    post_id         int      null,
    filename        text     null,
    stored_filename text     null,
    file_size       int      null,
    uploaded_at     datetime null
);

create table group_board_posts
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

create table group_project_issue_attachments
(
    id              int unsigned auto_increment
        primary key,
    issue_id        int      null,
    filename        text     null,
    stored_filename text     null,
    file_size       int      null,
    uploaded_at     datetime null
);

create table group_project_issues
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

create table group_project_todo_attachments
(
    id              int unsigned auto_increment
        primary key,
    todo_id         int      null,
    filename        text     null,
    stored_filename text     null,
    file_size       int      null,
    uploaded_at     datetime null
);

create table group_project_todos
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

create table group_projects
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

create table info_board_attachments
(
    id              int unsigned auto_increment
        primary key,
    post_id         int      null,
    filename        text     null,
    stored_filename text     null,
    file_size       int      null,
    uploaded_at     datetime null
);

create table info_board_posts
(
    id         int unsigned auto_increment
        primary key,
    title      text     null,
    content    text     null,
    created_by text     null,
    created_at datetime null,
    updated_at datetime null
);

create table inspection_areas
(
    id         int unsigned auto_increment
        primary key,
    code       text null,
    name       text null,
    sort_order int  null,
    is_active  int  null
);

create table inspection_locations
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

create table inspection_photos
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
    on inspection_photos (component_id);

create table inspection_sheets
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

create table instrument_import_error_rows
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
    on instrument_import_error_rows (import_log_id);

create table instrument_import_logs
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

create table instrument_usage_headers
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

create table instrument_usage_items
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

create table issue_attachments
(
    id              int unsigned auto_increment
        primary key,
    issue_id        int      null,
    filename        text     null,
    stored_filename text     null,
    file_size       int      null,
    uploaded_at     datetime null
);

create table issues
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

create table job_types
(
    id            int auto_increment
        primary key,
    code          varchar(50)   not null,
    name          varchar(255)  not null,
    display_order int default 0 null,
    constraint uq_job_types_code
        unique (code)
);

create table labels
(
    id         int unsigned auto_increment
        primary key,
    data_json  text     null,
    created_at datetime null,
    updated_at datetime null
);

create table layouts
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

create table ledger_entries
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
    on ledger_entries (ledger_layout_id);

create table ledger_group_settings
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
    on ledger_group_settings (group_id);

create index idx_ledger_group_settings_ledger_layout_id
    on ledger_group_settings (ledger_layout_id);

create table ledger_layouts
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

create table ledger_numbering_counters
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
    on ledger_numbering_counters (group_id);

create table login_logs
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
    on login_logs (employee_id);

create index idx_login_logs_login_at
    on login_logs (login_at);

create table mail_lists
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

create table manual_attachment_views
(
    id            int unsigned auto_increment
        primary key,
    attachment_id int      null,
    user_id       text     null,
    downloaded_at datetime null
);

create table manual_attachments
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

create table manual_views
(
    id        int unsigned auto_increment
        primary key,
    manual_id int      null,
    user_id   text     null,
    viewed_at datetime null
);

create table manuals
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

create table measuring_instrument_usage_history
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

create table measuring_instruments
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

create table notices
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

create table outsourcing_costs
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
    on outsourcing_costs (expense_month);

create index idx_outsourcing_costs_project_id
    on outsourcing_costs (project_id);

create table overtime_alert_logs
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

create table overtime_overlimit_requests
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

create table overtime_plans
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

create table overtime_requests
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

create table page_views
(
    id          int unsigned auto_increment
        primary key,
    page_name   text     null,
    view_count  int      null,
    last_viewed datetime null
);

create table pages
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
        foreign key (parent_id) references pages (id)
            on delete set null
);

create table blocks
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
        foreign key (page_id) references pages (id)
            on delete cascade
);

create index page_id
    on blocks (page_id);

create index parent_id
    on pages (parent_id);

create table partial_shipment
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

create table pending_projects
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
    on pending_projects (owner_group_name);

create index idx_pending_projects_project_id
    on pending_projects (project_id);

create index idx_pending_projects_status
    on pending_projects (status);

create index idx_pending_projects_sub3_id
    on pending_projects (sub3_id);

create table personal_todos
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

create table project_chat_messages
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
    on project_chat_messages (project_id);

create index idx_project_chat_messages_sender_employee_id
    on project_chat_messages (sender_employee_id);

create table project_ifs_items
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
    on project_ifs_items (project_id);

create table project_manage_table
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

create table project_management
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

create table project_order_components
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
    on project_order_components (dept_code);

create index idx_project_order_components_order_number
    on project_order_components (order_number);

create index idx_project_order_components_project_id
    on project_order_components (project_id);

create table projects
(
    id         int unsigned auto_increment
        primary key,
    page_id    int  null,
    start_date date null,
    end_date   date null
);

create table qa
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

create index answerer_id
    on qa (answerer_id);

create index questioner_id
    on qa (questioner_id);

create table qa_attachments
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

create table qa_topics
(
    id         int unsigned auto_increment
        primary key,
    title      text     null,
    category1  text     null,
    category2  text     null,
    creator_id text     null,
    created_at datetime null
);

create table shipping_master
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
    on shipping_master (project_id);

create table skill_business_types
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
    on skill_business_types (job_type_id);

create table skill_evaluation_levels
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

create table skills
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
    on skills (business_type_id);

create index idx_skills_default_required_level_id
    on skills (default_required_level_id);

create index idx_skills_job_type_id
    on skills (job_type_id);

create table solution_portal_categories
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

create table solution_portal_links
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
    on solution_portal_links (category_id);

create table solution_portal_stats
(
    page_name  varchar(100)  not null
        primary key,
    view_count int default 0 not null
);

create table sub3_group_access
(
    id         int auto_increment
        primary key,
    sub3_id    varchar(3)   not null,
    group_name varchar(255) not null
);

create index idx_sub3_group_access_group_name
    on sub3_group_access (group_name);

create index idx_sub3_group_access_sub3_id
    on sub3_group_access (sub3_id);

create table sub3_master
(
    sub3_id     varchar(3)                           not null
        primary key,
    name        varchar(100)                         not null,
    description text                                 null,
    active      tinyint(1) default 1                 not null,
    updated_at  datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create table subproject_bind
(
    id           int auto_increment
        primary key,
    jrc_group_id int         not null comment 'グループID',
    variety      varchar(10) not null comment 'サブプロジェクト種別',
    constraint subproject_bind_group_kind_table_jrc_group_id_fk
        foreign key (jrc_group_id) references ifs_reference_data.group_kind_table (jrc_group_id)
);

create table system_assignments
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

create table system_groups
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

create table system_manual_document_versions
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

create table system_manual_documents
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

create table system_roles
(
    id            int unsigned auto_increment
        primary key,
    name          text null,
    display_order int  null,
    is_active     int  null
);

create table system_versions
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

create table task_attachments
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

create table task_confirmations
(
    id           int unsigned auto_increment
        primary key,
    task_id      int        null,
    employee_id  text       null,
    confirmed    tinyint(1) null,
    confirmed_at datetime   null
);

create table tasks
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

create table th_devices
(
    id            int unsigned auto_increment
        primary key,
    serial_number text null,
    name          text null,
    location      text null,
    enabled       int  null
);

create table th_measurements
(
    id            int unsigned auto_increment
        primary key,
    device_id     int    null,
    timestamp     text   null,
    temperature_c double null,
    humidity_rh   double null
);

create table todo_template_groups
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

create table todo_templates
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
    on todo_templates (group_id);

create table todos
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
    on todos (due_date);

create table travel_costs
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
    on travel_costs (expense_month);

create index idx_travel_costs_project_id
    on travel_costs (project_id);

create table update_project_info
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

create table usage_format_placeholders
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
    on usage_format_placeholders (template_id);

create table usage_format_templates
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

create table user_affiliation_histories
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
    on user_affiliation_histories (employee_id);

create index idx_user_affiliation_histories_group_code
    on user_affiliation_histories (group_code);

create index idx_user_affiliation_histories_group_name
    on user_affiliation_histories (group_name);

create table user_job_types
(
    id          int auto_increment
        primary key,
    employee_id varchar(32)          not null,
    job_type_id int                  not null,
    is_primary  tinyint(1) default 0 null
);

create index idx_user_job_types_employee_id
    on user_job_types (employee_id);

create index idx_user_job_types_job_type_id
    on user_job_types (job_type_id);

create table user_requests
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
    on user_requests (employee_id);

create index idx_user_requests_status
    on user_requests (status);

create table user_skill_history
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
    on user_skill_history (batch_id);

create index idx_user_skill_history_employee_id
    on user_skill_history (employee_id);

create index idx_user_skill_history_skill_id
    on user_skill_history (skill_id);

create table user_skill_self_batches
(
    id          bigint auto_increment
        primary key,
    employee_id varchar(20)                        not null,
    saved_at    datetime default CURRENT_TIMESTAMP not null
);

create index idx_user_skill_self_batches_employee_id
    on user_skill_self_batches (employee_id);

create table user_skills
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
    on user_skills (employee_id);

create index idx_user_skills_manager_level_id
    on user_skills (manager_level_id);

create index idx_user_skills_self_level_id
    on user_skills (self_level_id);

create index idx_user_skills_skill_id
    on user_skills (skill_id);

create table users
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

create table videos
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

create table view_history
(
    id                int unsigned auto_increment
        primary key,
    user_id           varchar(32) null,
    video_id          int         null,
    viewed_at         datetime    null,
    view_duration     int         null,
    completion_status text        null
);

create table witness_result_files
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
    on witness_result_files (project_id);

create table work_hour_rates
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
    on work_hour_rates (year);

create table work_raw_actuals
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

create table work_raw_actuals_import_logs
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
    on work_raw_actuals_import_logs (file_path);

create index idx_work_raw_actuals_import_logs_imported_at
    on work_raw_actuals_import_logs (imported_at);

