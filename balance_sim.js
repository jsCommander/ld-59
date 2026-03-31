// Balance Simulator — Баговый Офис
// node balance_sim.js

const BASE = 100;

const ARCHETYPES = {
  dev: { name: "Разработчик", capacity: 5, bugs_per_tasks: 8, salary_mult: 2.5 },
  vibe: { name: "Вайбкодер", capacity: 8, bugs_per_tasks: 5, salary_mult: 1 },
  senior: { name: "Сеньор", capacity: 5, bugs_per_tasks: -12, salary_mult: 5 },
};

const PHASES = [
  { name: "MVP", sprints: [1, 3], desks: 3, bug_multiplier: 0.5 },
  { name: "Демо", sprints: [4, 6], desks: 5, bug_multiplier: 1.0 },
  { name: "Инвестиции", sprints: [7, 9], desks: 7, bug_multiplier: 0.8 },
  { name: "Релиз", sprints: [10, 12], desks: 9, bug_multiplier: 1.2 },
];

const STARTING_BUDGET = BASE * 20; // 2000$
const BANKRUPT_THRESHOLD = BASE * -30; // -3000$ = банкрот

const SCENARIOS = [
  {
    name: "Полный вайбкод",
    hires: { 1: ["vibe", "vibe", "vibe"], 4: ["vibe", "vibe"], 7: ["vibe", "vibe"], 10: ["vibe", "vibe"] },
    strategy: "ignore_bugs",
  },
  {
    name: "Полный вайбкод (чинит баги)",
    hires: { 1: ["vibe", "vibe", "vibe"], 4: ["vibe", "vibe"], 7: ["vibe", "vibe"], 10: ["vibe", "vibe"] },
    strategy: "fix_bugs_first",
  },
  {
    name: "Все разрабы",
    hires: { 1: ["dev", "dev", "dev"], 4: ["dev", "dev"], 7: ["dev", "dev"], 10: ["dev", "dev"] },
    strategy: "fix_bugs_first",
  },
  {
    name: "Разрабы + сеньоры",
    hires: { 1: ["dev", "dev", "senior"], 4: ["dev", "senior"], 7: ["dev", "senior"], 10: ["dev", "senior"] },
    strategy: "fix_bugs_first",
  },
  {
    name: "Вайбкод → сеньоры на спасение",
    hires: { 1: ["vibe", "vibe", "vibe"], 4: ["senior", "senior"], 7: ["senior", "senior"], 10: ["senior", "senior"] },
    strategy: "fix_bugs_first",
  },
  {
    name: "Микс (разраб + вайб + сеньор)",
    hires: { 1: ["dev", "vibe", "senior"], 4: ["dev", "vibe"], 7: ["dev", "senior"], 10: ["dev", "vibe"] },
    strategy: "fix_bugs_first",
  },
  {
    name: "Все сеньоры",
    hires: { 1: ["senior", "senior", "senior"], 4: ["senior", "senior"], 7: ["senior", "senior"], 10: ["senior", "senior"] },
    strategy: "fix_bugs_first",
  },
  {
    name: "Разрабы → вайбкод",
    hires: { 1: ["dev", "dev", "dev"], 4: ["vibe", "vibe"], 7: ["vibe", "vibe"], 10: ["vibe", "vibe"] },
    strategy: "fix_bugs_first",
  },
  ...generateRandomScenarios(10),
];

// --- Генерация случайных сценариев ---

function generateRandomScenarios(count) {
  const archs = ["dev", "vibe", "senior"];
  const letter = { dev: "D", vibe: "V", senior: "S" };
  const scenarios = [];

  for (let i = 0; i < count; i++) {
    const pick = (n) => Array.from({ length: n }, () => archs[Math.floor(Math.random() * 3)]);
    const hires = { 1: pick(3), 4: pick(2), 7: pick(2), 10: pick(2) };
    const name = Object.values(hires).map(h => h.map(a => letter[a]).join("")).join("-");
    scenarios.push({ name, hires, strategy: "fix_bugs_first" });
  }
  return scenarios;
}

// --- Спринт-генератор ---

function getPhase(sprint) {
  return PHASES.find(p => sprint >= p.sprints[0] && sprint <= p.sprints[1]);
}

function getAvgBugPriority(tech_debt) {
  if (tech_debt >= 40) return 2.5;
  if (tech_debt >= 15) return 2.0;
  return 1.0;
}

function generateSprint(tech_debt, phase) {
  const bugs_count = Math.floor(tech_debt * phase.bug_multiplier);
  const avg_priority = getAvgBugPriority(tech_debt);
  const bugs = [];
  for (let i = 0; i < bugs_count; i++) {
    bugs.push({ priority: avg_priority });
  }
  return { bugs };
}

function calculateTechDebt(team, tasks_done) {
  let debt = 0;
  for (const dev of team) {
    if (dev.bugs_per_tasks > 0) {
      debt += tasks_done[dev.id] / dev.bugs_per_tasks;
    } else if (dev.bugs_per_tasks < 0) {
      debt -= tasks_done[dev.id] / Math.abs(dev.bugs_per_tasks);
    }
  }
  return Math.max(0, debt);
}

function distributeTasks(team, bugs, strategy) {
  const total_capacity = team.reduce((s, d) => s + d.capacity, 0);
  let features_done = 0;
  let bugs_fixed = 0;
  let bugs_remaining;

  if (strategy === "fix_bugs_first") {
    let capacity_left = total_capacity;
    bugs_fixed = Math.min(bugs.length, capacity_left);
    capacity_left -= bugs_fixed;
    bugs_remaining = bugs.slice(bugs_fixed); // нерешённые баги с их priority
    features_done = capacity_left;
  } else {
    features_done = total_capacity;
    bugs_remaining = bugs;
  }

  return { features_done, bugs_fixed, bugs_remaining, total_capacity };
}

function updateTasksDone(team, total_capacity, total_tasks, tasks_done) {
  for (const dev of team) {
    const dev_tasks = Math.round((dev.capacity / total_capacity) * total_tasks);
    tasks_done[dev.id] += dev_tasks;
  }
}

function calculateFinances(features_done, bugs_remaining, team, phase) {
  const income = features_done * BASE;
  const salaries = team.reduce((s, d) => s + d.salary_mult * BASE, 0);
  const rent = phase.desks * BASE;
  const penalty = bugs_remaining.reduce((s, b) => s + BASE * b.priority, 0);
  return { income, salaries, rent, penalty };
}

// --- Симуляция ---

function simulate(scenario) {
  let budget = STARTING_BUDGET;
  let tech_debt = 0;
  const tasks_done = {};
  const team = [];
  let sprints_in_negative = 0;
  let dead = false;
  let dead_at = null;
  const log = [];

  for (let sprint = 1; sprint <= 12; sprint++) {
    const phase = getPhase(sprint);

    // Найм
    const new_hires = scenario.hires[sprint];
    if (new_hires) {
      for (const arch of new_hires) {
        const id = team.length;
        team.push({ ...ARCHETYPES[arch], id, archetype: arch });
        tasks_done[id] = 0;
      }
    }

    // Генерация спринта
    const { bugs } = generateSprint(tech_debt, phase);

    // Распределение задач
    const { features_done, bugs_fixed, bugs_remaining, total_capacity } =
      distributeTasks(team, bugs, scenario.strategy);

    // Обновление тасок по разрабам
    updateTasksDone(team, total_capacity, features_done + bugs_fixed, tasks_done);

    // Пересчёт техдолга
    tech_debt = calculateTechDebt(team, tasks_done);

    // Финансы
    const { income, salaries, rent, penalty } = calculateFinances(
      features_done, bugs_remaining, team, phase
    );
    budget += income - salaries - rent - penalty;

    // Банкротство
    if (budget <= BANKRUPT_THRESHOLD) {
      dead = true;
      dead_at = sprint;
    }

    const team_comp = team.map(d => d.archetype === "dev" ? "D" : d.archetype === "vibe" ? "V" : "S").join("");

    log.push({
      sprint,
      phase: phase.name,
      team_comp,
      capacity: total_capacity,
      bugs_in: bugs.length,
      bugs_fixed,
      bugs_ignored: bugs_remaining.length,
      features: features_done,
      income,
      salaries,
      rent,
      penalty,
      budget: Math.round(budget),
      tech_debt: Math.round(tech_debt * 100) / 100,
    });

    if (dead) break;
  }

  return { scenario: scenario.name, log, dead, dead_at };
}

// --- Вывод ---

console.log("=".repeat(120));
console.log("BALANCE SIMULATOR");
console.log("=".repeat(120));

for (const scenario of SCENARIOS) {
  const result = simulate(scenario);

  console.log(`\n${"─".repeat(120)}`);
  console.log(`▶ ${result.scenario}${result.dead ? ` — БАНКРОТ на спринте ${result.dead_at}` : " — ВЫЖИЛ"}`);
  console.log(`${"─".repeat(120)}`);

  console.log(
    "Sprint".padEnd(8) +
    "Phase".padEnd(14) +
    "Team".padEnd(12) +
    "Cap".padEnd(6) +
    "Bugs→".padEnd(7) +
    "Fixed".padEnd(7) +
    "Skip".padEnd(7) +
    "Feat".padEnd(7) +
    "Income".padEnd(9) +
    "Salary".padEnd(9) +
    "Rent".padEnd(7) +
    "Penalty".padEnd(9) +
    "Budget".padEnd(10) +
    "Debt".padEnd(8)
  );

  for (const s of result.log) {
    console.log(
      String(s.sprint).padEnd(8) +
      s.phase.padEnd(14) +
      s.team_comp.padEnd(12) +
      String(s.capacity).padEnd(6) +
      String(s.bugs_in).padEnd(7) +
      String(s.bugs_fixed).padEnd(7) +
      String(s.bugs_ignored).padEnd(7) +
      String(s.features).padEnd(7) +
      String(s.income).padEnd(9) +
      String(s.salaries).padEnd(9) +
      String(s.rent).padEnd(7) +
      String(s.penalty).padEnd(9) +
      String(s.budget).padEnd(10) +
      String(s.tech_debt).padEnd(8)
    );
  }
}
