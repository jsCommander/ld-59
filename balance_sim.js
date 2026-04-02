// Balance Simulator v2 — Баговый Офис
// node balance_sim.js

const BASE = 100;

const ARCHETYPES = {
  vibe: { name: "Вайбкодер", speed: 80, quality: 30, refactoring: 10, salary_mult: 1 },
  dev: { name: "Разработчик", speed: 50, quality: 70, refactoring: 50, salary_mult: 2.5 },
  senior: { name: "Сеньор", speed: 50, quality: 100, refactoring: 90, salary_mult: 5 },
};

const PHASES = [
  { name: "MVP", sprints: [1, 3], desks: 3, bug_multiplier: 0.5 },
  { name: "Демо", sprints: [4, 6], desks: 5, bug_multiplier: 1.0 },
  { name: "Инвестиции", sprints: [7, 9], desks: 7, bug_multiplier: 0.8 },
  { name: "Релиз", sprints: [10, 12], desks: 9, bug_multiplier: 1.2 },
];

const STARTING_BUDGET = BASE * 25; // 2500$
const DEBT_PER_TASK = 0.6;
const REFACTOR_TASK_VALUE = 5;

const SCENARIOS = [
  {
    name: "Вайбкод (игнорит баги)",
    hires: { 1: ["vibe", "vibe", "vibe"], 4: ["vibe", "vibe"], 7: ["vibe", "vibe"], 10: ["vibe", "vibe"] },
    strategy: "ignore_bugs",
    refactor_sprints: [],
  },
  {
    name: "Вайбкод (чинит баги)",
    hires: { 1: ["vibe", "vibe", "vibe"], 4: ["vibe", "vibe"], 7: ["vibe", "vibe"], 10: ["vibe", "vibe"] },
    strategy: "fix_bugs_first",
    refactor_sprints: [],
  },
  {
    name: "Вайбкод + рефакторинг",
    hires: { 1: ["vibe", "vibe", "vibe"], 4: ["vibe", "vibe"], 7: ["vibe", "vibe"], 10: ["vibe", "vibe"] },
    strategy: "fix_bugs_first",
    refactor_sprints: [3, 6, 9],
  },
  {
    name: "Все разрабы",
    hires: { 1: ["dev", "dev", "dev"], 4: ["dev", "dev"], 7: ["dev", "dev"], 10: ["dev", "dev"] },
    strategy: "fix_bugs_first",
    refactor_sprints: [],
  },
  {
    name: "Все разрабы + рефакторинг",
    hires: { 1: ["dev", "dev", "dev"], 4: ["dev", "dev"], 7: ["dev", "dev"], 10: ["dev", "dev"] },
    strategy: "fix_bugs_first",
    refactor_sprints: [3, 6, 9],
  },
  {
    name: "Разрабы + сеньоры",
    hires: { 1: ["dev", "dev", "senior"], 4: ["dev", "senior"], 7: ["dev", "senior"], 10: ["dev", "senior"] },
    strategy: "fix_bugs_first",
    refactor_sprints: [],
  },
  {
    name: "Разрабы + сеньоры + рефакт",
    hires: { 1: ["dev", "dev", "senior"], 4: ["dev", "senior"], 7: ["dev", "senior"], 10: ["dev", "senior"] },
    strategy: "fix_bugs_first",
    refactor_sprints: [6, 9],
  },
  {
    name: "Вайбкод → сеньоры + рефакт",
    hires: { 1: ["vibe", "vibe", "vibe"], 4: ["senior", "senior"], 7: ["senior", "senior"], 10: ["senior", "senior"] },
    strategy: "fix_bugs_first",
    refactor_sprints: [5, 8],
  },
  {
    name: "Микс (D+V+S)",
    hires: { 1: ["dev", "vibe", "senior"], 4: ["dev", "vibe"], 7: ["dev", "senior"], 10: ["dev", "vibe"] },
    strategy: "fix_bugs_first",
    refactor_sprints: [6, 9],
  },
  {
    name: "Все сеньоры",
    hires: { 1: ["senior", "senior", "senior"], 4: ["senior", "senior"], 7: ["senior", "senior"], 10: ["senior", "senior"] },
    strategy: "fix_bugs_first",
    refactor_sprints: [],
  },
  {
    name: "Микс: никогда не рефакторить",
    hires: { 1: ["dev", "vibe", "senior"], 4: ["vibe", "vibe"], 7: ["dev", "vibe"], 10: ["vibe", "vibe"] },
    strategy: "fix_bugs_first",
    refactor_sprints: [],
  },
  {
    name: "Микс: рефакт каждые 3",
    hires: { 1: ["dev", "vibe", "senior"], 4: ["vibe", "vibe"], 7: ["dev", "vibe"], 10: ["vibe", "vibe"] },
    strategy: "fix_bugs_first",
    refactor_sprints: [3, 6, 9, 12],
  },
  {
    name: "Микс: рефакт в конце фаз",
    hires: { 1: ["dev", "vibe", "senior"], 4: ["vibe", "vibe"], 7: ["dev", "vibe"], 10: ["vibe", "vibe"] },
    strategy: "fix_bugs_first",
    refactor_sprints: [3, 6, 9],
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
    const refactor_count = Math.floor(Math.random() * 4);
    const possible = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    const refactor_sprints = [];
    for (let j = 0; j < refactor_count; j++) {
      const idx = Math.floor(Math.random() * possible.length);
      refactor_sprints.push(possible.splice(idx, 1)[0]);
    }
    refactor_sprints.sort((a, b) => a - b);
    scenarios.push({ name, hires, strategy: "fix_bugs_first", refactor_sprints });
  }
  return scenarios;
}

// --- Формулы ---

function getPhase(sprint) {
  return PHASES.find(p => sprint >= p.sprints[0] && sprint <= p.sprints[1]);
}

function getAvgBugPriority(tech_debt) {
  if (tech_debt >= 90) return 2.5;
  if (tech_debt >= 60) return 2.0;
  if (tech_debt >= 30) return 1.5;
  return 1.0;
}

function generateSprint(tech_debt, phase) {
  const bugs_count = Math.floor(tech_debt * 0.5 * phase.bug_multiplier);
  const avg_priority = getAvgBugPriority(tech_debt);
  const bugs = [];
  for (let i = 0; i < bugs_count; i++) {
    bugs.push({ priority: avg_priority });
  }
  return { bugs };
}

function getTeamCapacity(team) {
  return team.reduce((s, d) => s + d.speed, 0) / 10;
}

function getTeamAvgQuality(team) {
  if (team.length === 0) return 50;
  return team.reduce((s, d) => s + d.quality, 0) / team.length;
}

function calculateDebtFromWork(work_done, avg_quality) {
  return work_done * ((100 - avg_quality) / 100) * DEBT_PER_TASK;
}

function calculateRefactorReduction(team) {
  let total = 0;
  for (const dev of team) {
    const tasks = dev.speed / 10;
    total += tasks * REFACTOR_TASK_VALUE * (dev.refactoring / 100);
  }
  return total;
}

function distributeTasks(team, bugs, strategy) {
  const total_capacity = getTeamCapacity(team);
  let features_done = 0;
  let bugs_fixed = 0;
  let bugs_remaining;

  if (strategy === "fix_bugs_first") {
    let capacity_left = total_capacity;
    bugs_fixed = Math.min(bugs.length, capacity_left);
    capacity_left -= bugs_fixed;
    bugs_remaining = bugs.slice(bugs_fixed);
    features_done = capacity_left;
  } else {
    features_done = total_capacity;
    bugs_remaining = bugs;
  }

  return { features_done, bugs_fixed, bugs_remaining, total_capacity };
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
  const team = [];
  let dead = false;
  let dead_at = null;
  const log = [];
  const refactor_set = new Set(scenario.refactor_sprints || []);

  for (let sprint = 1; sprint <= 12; sprint++) {
    const phase = getPhase(sprint);

    // Найм
    const new_hires = scenario.hires[sprint];
    if (new_hires) {
      for (const arch of new_hires) {
        const id = team.length;
        team.push({ ...ARCHETYPES[arch], id, archetype: arch });
      }
    }

    // Генерация спринта
    const { bugs } = generateSprint(tech_debt, phase);
    const is_refactor = refactor_set.has(sprint);

    let features_done = 0;
    let bugs_fixed = 0;
    let bugs_remaining = bugs;
    let total_capacity = getTeamCapacity(team);

    if (is_refactor) {
      // Рефакторинг-спринт: 0 фич, 0 фиксов, снижаем долг
      const debt_removed = calculateRefactorReduction(team);
      tech_debt = Math.max(0, tech_debt - debt_removed);
    } else {
      // Обычный спринт
      const result = distributeTasks(team, bugs, scenario.strategy);
      features_done = result.features_done;
      bugs_fixed = result.bugs_fixed;
      bugs_remaining = result.bugs_remaining;

      // Техдолг от работы
      const work_done = features_done + bugs_fixed;
      const avg_quality = getTeamAvgQuality(team);
      const debt_added = calculateDebtFromWork(work_done, avg_quality);
      tech_debt = Math.min(100, tech_debt + debt_added);
    }

    // Финансы
    const { income, salaries, rent, penalty } = calculateFinances(
      features_done, bugs_remaining, team, phase
    );
    budget += income - salaries - rent - penalty;

    // Банкротство на нуле
    if (budget <= 0) {
      budget = 0;
      dead = true;
      dead_at = sprint;
    }

    const team_comp = team.map(d => d.archetype === "dev" ? "D" : d.archetype === "vibe" ? "V" : "S").join("");

    log.push({
      sprint,
      phase: phase.name,
      team_comp,
      capacity: total_capacity,
      is_refactor,
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

console.log("=".repeat(140));
console.log("BALANCE SIMULATOR v2 — speed/quality/refactoring, bankrupt at 0");
console.log("=".repeat(140));

for (const scenario of SCENARIOS) {
  const result = simulate(scenario);

  console.log(`\n${"─".repeat(140)}`);
  console.log(`▶ ${result.scenario}${result.dead ? ` — БАНКРОТ на спринте ${result.dead_at}` : " — ВЫЖИЛ"}`);
  console.log(`${"─".repeat(140)}`);

  console.log(
    "Sprint".padEnd(8) +
    "Phase".padEnd(14) +
    "Team".padEnd(12) +
    "Spd".padEnd(6) +
    "Ref".padEnd(5) +
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
      (s.is_refactor ? "R" : "").padEnd(5) +
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
