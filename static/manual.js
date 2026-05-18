const elements = {
  summaryGrid: document.getElementById("summaryGrid"),
  generatedAt: document.getElementById("generatedAt"),
  overviewList: document.getElementById("overviewList"),
  supportEndpoints: document.getElementById("supportEndpoints"),
  routePrefix: document.getElementById("routePrefix"),
  filteringBehavior: document.getElementById("filteringBehavior"),
  queryParameters: document.getElementById("queryParameters"),
  responses: document.getElementById("responses"),
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
    { label: "補助エンドポイント", value: spec.support_endpoints.length },
    { label: "テーブルAPI", value: spec.table_read_api.table_endpoints.length },
    {
      label: "取得カラム数",
      value: spec.table_read_api.table_endpoints.reduce(
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

function renderQueryParameters(items) {
  elements.queryParameters.replaceChildren();

  items.forEach((parameter) => {
    const card = createElement("article", "parameter-card");
    const line = createElement("div", "parameter-line");
    line.append(
      createElement("strong", "", parameter.name),
      createElement(
        "span",
        "schema-badge ok",
        parameter.required ? "必須" : "任意",
      ),
    );

    const typeText = createElement(
      "p",
      "card-note",
      `${parameter.data_type} / ${parameter.description}`,
    );

    card.append(line, typeText);
    elements.queryParameters.appendChild(card);
  });
}

function renderResponses(items) {
  elements.responses.replaceChildren();

  items.forEach((response) => {
    const card = createElement("article", "response-card");
    const line = createElement("div", "response-line");
    const statusClass = response.status >= 400 ? "status-badge warn" : "status-badge ok";

    line.append(
      createElement("span", statusClass, String(response.status)),
      createElement("strong", "", response.body),
    );

    card.append(line, createElement("p", "card-note", response.description));
    elements.responses.appendChild(card);
  });
}

function createColumnsTable(columns) {
  const wrapper = createElement("div", "columns-wrap");
  const table = createElement("table");
  const thead = createElement("thead");
  const headerRow = createElement("tr");
  ["列名", "型", "DB型", "NULL許可", "キー", "順序"].forEach((label) => {
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

function renderTableEndpoints(items) {
  elements.tableCards.replaceChildren();
  elements.emptyNote.hidden = items.length !== 0;

  items.forEach((endpoint) => {
    const cardClass = endpoint.schema_found ? "table-card" : "table-card warn";
    const card = createElement("article", cardClass);
    const head = createElement("div", "table-card-head");
    const titleGroup = createElement("div");
    titleGroup.append(
      createElement("h3", "", endpoint.table_name),
      createElement("p", "model-name", endpoint.model_name),
    );

    const badgeClass = endpoint.schema_found ? "schema-badge ok" : "schema-badge warn";
    const badgeText = endpoint.schema_found ? "スキーマ取得済み" : "スキーマ未取得";
    head.append(titleGroup, createElement("span", badgeClass, badgeText));

    card.append(
      head,
      createElement("p", "table-path", endpoint.path),
      createElement("p", "card-note", endpoint.summary),
    );

    const sample = createElement("code", "sample-request", endpoint.sample_request);
    card.appendChild(sample);

    if (endpoint.columns.length === 0) {
      card.appendChild(
        createElement(
          "p",
          "card-note",
          "information_schema から列情報を取得できませんでした。対象テーブルが現在のDBに存在しない可能性があります。",
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
    throw new Error(`/api/spec が HTTP ${response.status} を返しました`);
  }

  return response.json();
}

async function loadManual() {
  try {
    const spec = await fetchSpecification();
    allTableEndpoints = spec.table_read_api.table_endpoints;

    renderSummary(spec);
    elements.generatedAt.textContent = `生成日時: ${spec.generated_at}`;
    renderStringList(elements.overviewList, spec.overview);
    renderSupportEndpoints(spec.support_endpoints);

    elements.routePrefix.textContent = `${spec.table_read_api.method} ${spec.table_read_api.route_prefix}<table_name>`;
    renderStringList(elements.filteringBehavior, spec.table_read_api.filtering_behavior);
    renderQueryParameters(spec.table_read_api.query_parameters);
    renderResponses(spec.table_read_api.responses);
    renderTableEndpoints(allTableEndpoints);
  } catch (error) {
    elements.overviewList.replaceChildren(
      createElement("li", "", `API仕様の取得に失敗しました: ${error.message}`),
    );
  }
}

elements.tableSearch.addEventListener("input", filterTableEndpoints);
loadManual();
