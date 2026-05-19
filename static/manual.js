const elements = {
  summaryGrid: document.getElementById("summaryGrid"),
  generatedAt: document.getElementById("generatedAt"),
  overviewList: document.getElementById("overviewList"),
  allowedSchemas: document.getElementById("allowedSchemas"),
  supportEndpoints: document.getElementById("supportEndpoints"),
  getRoutePattern: document.getElementById("getRoutePattern"),
  getFilteringBehavior: document.getElementById("getFilteringBehavior"),
  getQueryParameters: document.getElementById("getQueryParameters"),
  getResponses: document.getElementById("getResponses"),
  postReadRoutePattern: document.getElementById("postReadRoutePattern"),
  postUpsertRoutePattern: document.getElementById("postUpsertRoutePattern"),
  postBehavior: document.getElementById("postBehavior"),
  postRequestFields: document.getElementById("postRequestFields"),
  postReadResponses: document.getElementById("postReadResponses"),
  postUpsertResponses: document.getElementById("postUpsertResponses"),
  tableCards: document.getElementById("tableCards"),
  tableSearch: document.getElementById("tableSearch"),
  emptyNote: document.getElementById("emptyNote"),
};

let allTableEndpoints = [];

function createElement(tagName, className, textContent) {
  const node = document.createElement(tagName);
  if (className) {
    node.className = className;
  }
  if (textContent !== undefined) {
    node.textContent = textContent;
  }
  return node;
}

function renderSummary(spec) {
  const cards = [
    { label: "許可スキーマ", value: spec.allowed_schema_specs.length },
    { label: "補助エンドポイント", value: spec.support_endpoints.length },
    { label: "テーブル API", value: spec.table_endpoints.length },
    {
      label: "総カラム数",
      value: spec.table_endpoints.reduce(
        (sum, endpoint) => sum + endpoint.columns.length,
        0,
      ),
    },
  ];

  elements.summaryGrid.replaceChildren();

  cards.forEach((card) => {
    const item = createElement("article", "metric");
    item.append(
      createElement("span", "metric-label", card.label),
      createElement("strong", "metric-value", String(card.value)),
    );
    elements.summaryGrid.appendChild(item);
  });
}

function renderAllowedSchemas(items) {
  elements.allowedSchemas.replaceChildren();

  items.forEach((schemaSpec) => {
    const card = createElement("article", "endpoint-card");
    const line = createElement("div", "endpoint-line");
    const badgeClass = schemaSpec.schema_found ? "schema-badge ok" : "schema-badge warn";
    const badgeText = schemaSpec.is_default ? "default" : "allowed";

    line.append(
      createElement("strong", "", schemaSpec.schema_name),
      createElement("span", badgeClass, badgeText),
    );

    const note = schemaSpec.schema_found
      ? `discoverable / allowlisted tables: ${schemaSpec.table_count}`
      : "information_schema で未検出";

    card.append(line, createElement("p", "card-note", note));
    elements.allowedSchemas.appendChild(card);
  });
}

function renderStringList(target, items) {
  target.replaceChildren();
  items.forEach((item) => {
    target.appendChild(createElement("li", "", item));
  });
}

function renderSupportEndpoints(items) {
  elements.supportEndpoints.replaceChildren();

  items.forEach((endpoint) => {
    const card = createElement("article", "endpoint-card");
    const line = createElement("div", "endpoint-line");
    line.append(
      createElement("span", "http-badge", endpoint.method),
      createElement("strong", "", endpoint.path),
    );
    card.append(line, createElement("p", "card-note", endpoint.summary));
    elements.supportEndpoints.appendChild(card);
  });
}

function renderRequestFields(target, items) {
  target.replaceChildren();

  items.forEach((parameter) => {
    const card = createElement("article", "parameter-card");
    const line = createElement("div", "parameter-line");
    line.append(
      createElement("strong", "", parameter.name),
      createElement(
        "span",
        `schema-badge ${parameter.required ? "warn" : "ok"}`,
        parameter.required ? "required" : "optional",
      ),
    );

    const typeText = createElement(
      "p",
      "card-note",
      `${parameter.data_type} / ${parameter.description}`,
    );

    card.append(line, typeText);
    target.appendChild(card);
  });
}

function renderResponses(target, items) {
  target.replaceChildren();

  items.forEach((response) => {
    const card = createElement("article", "response-card");
    const line = createElement("div", "response-line");
    const statusClass = response.status >= 400 ? "status-badge warn" : "status-badge ok";

    line.append(
      createElement("span", statusClass, String(response.status)),
      createElement("strong", "", response.body),
    );

    card.append(line, createElement("p", "card-note", response.description));
    target.appendChild(card);
  });
}

function createColumnsTable(columns) {
  const wrapper = createElement("div", "columns-wrap");
  const table = createElement("table");
  const thead = createElement("thead");
  const headerRow = createElement("tr");

  ["カラム", "型", "DB型", "NULL", "キー", "順序"].forEach((label) => {
    headerRow.appendChild(createElement("th", "", label));
  });
  thead.appendChild(headerRow);

  const tbody = createElement("tbody");
  columns.forEach((column) => {
    const row = createElement("tr");
    [
      column.name,
      column.data_type,
      column.column_type,
      column.nullable ? "可" : "不可",
      column.key_type || "-",
      String(column.ordinal_position),
    ].forEach((value) => {
      row.appendChild(createElement("td", "", value));
    });
    tbody.appendChild(row);
  });

  table.append(thead, tbody);
  wrapper.appendChild(table);
  return wrapper;
}

function createSampleBlock(method, title, sampleText) {
  const block = createElement("div", "sample-block");
  const head = createElement("div", "sample-head");
  const badge = createElement(
    "span",
    `http-badge ${method === "POST" ? "http-badge post" : ""}`,
    method,
  );
  head.append(badge, createElement("strong", "", title));
  block.append(head, createElement("pre", "sample-request sample-code", sampleText));
  return block;
}

function renderTableEndpoints(items) {
  elements.tableCards.replaceChildren();
  elements.emptyNote.hidden = items.length !== 0;

  items.forEach((endpoint) => {
    const cardClass = endpoint.schema_found ? "table-card" : "table-card warn";
    const card = createElement("article", cardClass);
    const head = createElement("div", "table-card-head");
    const titleGroup = createElement("div");
    titleGroup.append(
      createElement("h3", "", `${endpoint.schema_name}.${endpoint.table_name}`),
      createElement("p", "model-name", endpoint.model_name),
    );

    const badgeClass = endpoint.schema_found ? "schema-badge ok" : "schema-badge warn";
    const badgeText = endpoint.schema_found ? endpoint.schema_name : "schema missing";
    head.append(titleGroup, createElement("span", badgeClass, badgeText));

    const sampleGrid = createElement("div", "sample-grid");
    sampleGrid.append(
      createSampleBlock("GET", "query-string read", endpoint.get_sample_request),
      createSampleBlock("POST", "/read (search)", endpoint.post_read_sample_request),
      createSampleBlock("POST", "/update (upsert)", endpoint.post_upsert_sample_request),
    );

    card.append(
      head,
      createElement("p", "table-path", `JSON search path: ${endpoint.path}`),
      createElement("p", "card-note", endpoint.summary),
      sampleGrid,
    );

    if (endpoint.columns.length === 0) {
      card.appendChild(
        createElement(
          "p",
          "card-note",
          "information_schema にテーブル定義が見つからなかったため、実カラム一覧は表示できません。",
        ),
      );
    } else {
      card.appendChild(createColumnsTable(endpoint.columns));
    }

    elements.tableCards.appendChild(card);
  });
}

function filterTableEndpoints() {
  const keyword = elements.tableSearch.value.trim().toLowerCase();
  if (!keyword) {
    renderTableEndpoints(allTableEndpoints);
    return;
  }

  const filtered = allTableEndpoints.filter((endpoint) => {
    return (
      endpoint.schema_name.toLowerCase().includes(keyword) ||
      endpoint.table_name.toLowerCase().includes(keyword) ||
      endpoint.model_name.toLowerCase().includes(keyword)
    );
  });

  renderTableEndpoints(filtered);
}

async function fetchSpecification() {
  const response = await fetch("/api/spec", {
    headers: { Accept: "application/json" },
  });

  if (!response.ok) {
    throw new Error(`/api/spec returned HTTP ${response.status}`);
  }

  return response.json();
}

async function loadManual() {
  try {
    const spec = await fetchSpecification();
    allTableEndpoints = spec.table_endpoints;

    renderSummary(spec);
    elements.generatedAt.textContent = `生成日時: ${spec.generated_at}`;
    renderStringList(elements.overviewList, spec.overview);
    renderAllowedSchemas(spec.allowed_schema_specs);
    renderSupportEndpoints(spec.support_endpoints);

    elements.getRoutePattern.textContent = `${spec.table_get_api.method} ${spec.table_get_api.route_pattern}`;
    renderStringList(elements.getFilteringBehavior, spec.table_get_api.filtering_behavior);
    renderRequestFields(elements.getQueryParameters, spec.table_get_api.query_parameters);
    renderResponses(elements.getResponses, spec.table_get_api.responses);

    elements.postReadRoutePattern.textContent =
      `${spec.table_post_api.method} ${spec.table_post_api.read_route_pattern}`;
    elements.postUpsertRoutePattern.textContent =
      `${spec.table_post_api.method} ${spec.table_post_api.upsert_route_pattern}`;
    renderStringList(elements.postBehavior, spec.table_post_api.behavior);
    renderRequestFields(elements.postRequestFields, spec.table_post_api.request_fields);
    renderResponses(elements.postReadResponses, spec.table_post_api.read_responses);
    renderResponses(elements.postUpsertResponses, spec.table_post_api.upsert_responses);

    renderTableEndpoints(allTableEndpoints);
  } catch (error) {
    elements.overviewList.replaceChildren(
      createElement("li", "", `API 仕様の読み込みに失敗しました: ${error.message}`),
    );
  }
}

elements.tableSearch.addEventListener("input", filterTableEndpoints);
loadManual();
