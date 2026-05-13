const elements = {
  currentPath: document.getElementById("currentPath"),
  projectCount: document.getElementById("projectCount"),
  tableCount: document.getElementById("tableCount"),
  routeCount: document.getElementById("routeCount"),
  sourcePill: document.getElementById("sourcePill"),
  projectRows: document.getElementById("projectRows"),
  emptyState: document.getElementById("emptyState"),
  warnings: document.getElementById("warnings"),
  projectTables: document.getElementById("projectTables"),
  databaseTables: document.getElementById("databaseTables"),
  routeList: document.getElementById("routeList"),
  refreshButton: document.getElementById("refreshButton"),
};

const statusLabels = {
  implemented: "実装済み",
  read_only: "読み取り",
  placeholder: "入口のみ",
};

function textOrDash(value) {
  return value === null || value === undefined || value === "" ? "-" : String(value);
}

function renderWarnings(items) {
  elements.warnings.replaceChildren();

  if (!items || items.length === 0) {
    elements.warnings.hidden = true;
    return;
  }

  const title = document.createElement("strong");
  title.textContent = "確認事項";
  const list = document.createElement("ul");

  items.forEach((item) => {
    const row = document.createElement("li");
    row.textContent = item;
    list.appendChild(row);
  });

  elements.warnings.append(title, list);
  elements.warnings.hidden = false;
}

function renderProjects(projects) {
  elements.projectRows.replaceChildren();

  projects.forEach((project) => {
    const row = document.createElement("tr");
    [
      project.unique_project_id,
      project.project_name,
      project.client_name,
      project.status,
    ].forEach((value) => {
      const cell = document.createElement("td");
      cell.textContent = textOrDash(value);
      row.appendChild(cell);
    });
    elements.projectRows.appendChild(row);
  });

  elements.emptyState.hidden = projects.length !== 0;
}

function renderProjectTables(tables) {
  elements.projectTables.replaceChildren();
  tables.forEach((tableName) => {
    const chip = document.createElement("span");
    chip.className = "table-chip";
    chip.textContent = tableName;
    elements.projectTables.appendChild(chip);
  });
}

function renderDatabaseTables(tables) {
  elements.databaseTables.replaceChildren();
  tables.forEach((tableName) => {
    const row = document.createElement("li");
    row.textContent = tableName;
    elements.databaseTables.appendChild(row);
  });
}

function renderRoutes(routes) {
  elements.routeList.replaceChildren();

  routes.forEach((route) => {
    const item = document.createElement("article");
    item.className = "route-item";

    const title = document.createElement("div");
    title.className = "route-title";

    const method = document.createElement("span");
    method.className = "route-method";
    method.textContent = route.method;

    const name = document.createElement("strong");
    name.textContent = route.name;

    const status = document.createElement("span");
    status.className = `status-pill ${route.migration_status}`;
    status.textContent = statusLabels[route.migration_status] ?? route.migration_status;

    const path = document.createElement("code");
    path.textContent = route.path;

    const note = document.createElement("p");
    note.textContent = route.note;

    title.append(method, name, status);
    item.append(title, path, note);
    elements.routeList.appendChild(item);
  });
}

async function fetchJson(path) {
  const response = await fetch(path, { headers: { Accept: "application/json" } });
  if (!response.ok) {
    throw new Error(`${path}: HTTP ${response.status}`);
  }
  return response.json();
}

async function loadDashboard() {
  elements.refreshButton.disabled = true;
  elements.refreshButton.textContent = "更新中";
  elements.currentPath.textContent = window.location.pathname;

  try {
    const [snapshot, routes] = await Promise.all([
      fetchJson("/api/projects"),
      fetchJson("/api/routes"),
    ]);

    const projects = snapshot.projects ?? [];
    const dbTables = snapshot.database_tables ?? [];
    const projectTables = snapshot.project_tables ?? [];

    elements.projectCount.textContent = projects.length;
    elements.tableCount.textContent = dbTables.length;
    elements.routeCount.textContent = routes.length;
    elements.sourcePill.textContent = `${snapshot.source} / ${snapshot.fetched_at}`;

    renderWarnings(snapshot.fetch_warnings ?? []);
    renderProjects(projects);
    renderProjectTables(projectTables);
    renderDatabaseTables(dbTables);
    renderRoutes(routes);
  } catch (error) {
    renderWarnings([`API 取得に失敗しました: ${error.message}`]);
  } finally {
    elements.refreshButton.disabled = false;
    elements.refreshButton.textContent = "更新";
  }
}

elements.refreshButton.addEventListener("click", loadDashboard);
loadDashboard();
