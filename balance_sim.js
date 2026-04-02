// Balance Simulator v4 — Баговый Офис
// node balance_sim.js

const BASE = 100;

const ARCHETYPES = {
  V: { name: "Вайбкодер", feature: 80, bug: 20, refactor: 10, tech_debt: 70, salary_mult: 1 },
  D: { name: "Разработчик", feature: 50, bug: 50, refactor: 50, tech_debt: 30, salary_mult: 2.5 },
  S: { name: "Сеньор", feature: 30, bug: 70, refactor: 80, tech_debt: 0, salary_mult: 4 },
};

const PHASES = [
  { name: "MVP", sprints: [1, 3], desks: 3, bug_multiplier: 1.0 },
  { name: "Демо", sprints: [4, 6], desks: 5, bug_multiplier: 1.0 },
  { name: "Инвестиции", sprints: [7, 9], desks: 7, bug_multiplier: 1.0 },
  { name: "Релиз", sprints: [10, 12], desks: 9, bug_multiplier: 1.0 },
];

const STARTING_BUDGET = BASE * 25;
const DEBT_PER_TASK = 0.6;
const REFACTOR_TASK_VALUE = 2;
const PHASE_HIRE_SPRINTS = [1, 4, 7, 10];

// --- Конфиги сценариев ---
// team: буквы в порядке найма, через дефис по фазам (VVV-VV-VV-VV)
// bugs_to_ignore: сколько багов готовы пропустить за спринт
// refactor_above: порог техдолга, выше которого начинаем рефакторить

const SCENARIOS = [
  { name: "Вайбкод (игнор багов)",      team: "VVV-VV-VV-VV", bugs_to_ignore: 999, refactor_above: 999 },
  { name: "Вайбкод (0 багов)",          team: "VVV-VV-VV-VV", bugs_to_ignore: 0,   refactor_above: 999 },
  { name: "Вайбкод (рефакт >10)",       team: "VVV-VV-VV-VV", bugs_to_ignore: 0,   refactor_above: 10 },
  { name: "Разрабы",                    team: "DDD-DD-DD-DD", bugs_to_ignore: 0,   refactor_above: 999 },
  { name: "Разрабы (рефакт >30)",       team: "DDD-DD-DD-DD", bugs_to_ignore: 0,   refactor_above: 20 },
  { name: "Разрабы + сеньоры",          team: "DDS-DS-DS-DS", bugs_to_ignore: 0,   refactor_above: 999 },
  { name: "Разрабы + сеньоры (рефакт)", team: "DDS-DS-DS-DS", bugs_to_ignore: 0,   refactor_above: 20 },
  { name: "Сеньоры",                    team: "SSS-SS-SS-SS", bugs_to_ignore: 0,   refactor_above: 999 },
  { name: "Вайб→сеньоры",              team: "VVV-SS-SS-SS", bugs_to_ignore: 0,   refactor_above: 20 },
  { name: "Микс (DVS)",                 team: "DVS-DV-DS-DV", bugs_to_ignore: 0,   refactor_above: 20 },
  { name: "Микс (DVS) без рефакта",     team: "DVS-DV-DS-DV", bugs_to_ignore: 0,   refactor_above: 999 },
  { name: "Микс (DVS) игнор 3 бага",    team: "DVS-DV-DS-DV", bugs_to_ignore: 3,   refactor_above: 20 },
  { name: "Вайб+сеньор",                team: "VVS-VS-VS-VS", bugs_to_ignore: 0,   refactor_above: 20 },
  { name: "Вайб+разраб",                team: "VVD-VD-VD-VD", bugs_to_ignore: 0,   refactor_above: 20 },
];

// --- Парсинг команды ---

function parseTeam(teamStr) {
  const phases = teamStr.split("-");
  const hires = {};
  for (let i = 0; i < phases.length; i++) {
    hires[PHASE_HIRE_SPRINTS[i]] = phases[i].split("").map(letter => {
      const arch = ARCHETYPES[letter];
      if (!arch) throw new Error(`Unknown archetype: ${letter}`);
      return { ...arch, letter };
    });
  }
  return hires;
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

function generateBugs(tech_debt, phase) {
  const count = Math.floor(tech_debt * 0.5 * phase.bug_multiplier);
  const priority = getAvgBugPriority(tech_debt);
  return Array.from({ length: count }, () => ({ priority }));
}

// --- Оптимальное распределение задач ---
// Игрок назначает лучших юнитов на нужные задачи:
// 1. Лучшие по bug → фиксят баги (пока не покроют нужное количество)
// 2. Лучшие по refactor → рефакторят (если долг выше порога)
// 3. Остальные → фичи

function assignOptimally(team, bugs_count, bugs_to_ignore, tech_debt, refactor_above) {
  const bugs_to_fix = Math.max(0, bugs_count - bugs_to_ignore);
  const need_refactor = tech_debt > refactor_above;

  // Каждому разрабу назначаем роль
  const assignments = team.map(dev => ({ dev, role: null }));

  // Шаг 1: назначаем фиксеров багов (лучшие по bug стату, минимум людей)
  if (bugs_to_fix > 0) {
    const by_bug = [...assignments].sort((a, b) => b.dev.bug - a.dev.bug);
    let bug_cap = 0;
    for (const entry of by_bug) {
      if (bug_cap >= bugs_to_fix) break;
      entry.role = "bug";
      bug_cap += entry.dev.bug / 10;
    }
  }

  // Шаг 2: из оставшихся — рефакторинг (лучшие по refactor стату)
  if (need_refactor) {
    const unassigned = assignments.filter(a => !a.role);
    unassigned.sort((a, b) => b.dev.refactor - a.dev.refactor);
    for (const entry of unassigned) {
      entry.role = "refactor";
    }
  }

  // Шаг 3: все остальные → фичи
  for (const entry of assignments) {
    if (!entry.role) entry.role = "feature";
  }

  // Считаем результаты
  let bugs_fixed = 0, features_done = 0, refactor_done = 0;
  let debt_generated = 0;

  for (const { dev, role } of assignments) {
    const tasks = dev[role] / 10;
    if (role === "bug") {
      bugs_fixed += tasks;
    } else if (role === "feature") {
      features_done += tasks;
    } else {
      refactor_done += tasks;
    }
    // Каждый разраб генерит долг пропорционально сделанным задачам
    debt_generated += tasks * (dev.tech_debt / 100) * DEBT_PER_TASK;
  }

  // Не можем пофиксить больше багов чем есть
  bugs_fixed = Math.min(Math.floor(bugs_fixed), bugs_to_fix);
  features_done = Math.floor(features_done);
  refactor_done = Math.floor(refactor_done);

  const bugs_remaining = bugs_count - bugs_fixed;

  return { bugs_fixed, features_done, refactor_done, bugs_remaining, debt_generated };
}

// --- Симуляция ---

function simulate(scenario) {
  let budget = STARTING_BUDGET;
  let tech_debt = 0;
  const team = [];
  let dead = false;
  let dead_at = null;
  const log = [];
  const hires = parseTeam(scenario.team);

  for (let sprint = 1; sprint <= 12; sprint++) {
    const phase = getPhase(sprint);

    // Найм
    if (hires[sprint]) {
      for (const dev of hires[sprint]) {
        team.push({ ...dev, id: team.length });
      }
    }

    // Генерация багов
    const bugs = generateBugs(tech_debt, phase);

    // Оптимальное распределение
    const result = assignOptimally(
      team, bugs.length, scenario.bugs_to_ignore,
      tech_debt, scenario.refactor_above
    );

    // Техдолг
    const debt_removed = result.refactor_done * REFACTOR_TASK_VALUE;
    tech_debt = Math.max(0, Math.min(100, tech_debt + result.debt_generated - debt_removed));

    // Финансы
    const income = result.features_done * BASE;
    const salaries = team.reduce((s, d) => s + d.salary_mult * BASE, 0);
    const rent = phase.desks * BASE;
    const bug_priority = getAvgBugPriority(tech_debt);
    const penalty = result.bugs_remaining * BASE * bug_priority;

    budget += income - salaries - rent - penalty;

    if (budget <= 0) {
      budget = 0;
      dead = true;
      dead_at = sprint;
    }

    const team_comp = team.map(d => d.letter).join("");

    log.push({
      sprint, phase: phase.name, team_comp,
      bugs_in: bugs.length,
      ...result,
      income, salaries, rent, penalty,
      budget: Math.round(budget),
      tech_debt: Math.round(tech_debt * 100) / 100,
    });

    if (dead) break;
  }

  return { scenario: scenario.name, log, dead, dead_at };
}

// --- Вывод ---

function pad(val, w) { return String(val).padEnd(w); }

console.log("=".repeat(120));
console.log("BALANCE SIMULATOR v4 — optimal assignment, per-dev stats");
console.log("=".repeat(120));

for (const scenario of SCENARIOS) {
  const result = simulate(scenario);

  console.log(`\n${"─".repeat(120)}`);
  console.log(`▶ ${result.scenario}${result.dead ? ` — БАНКРОТ на спринте ${result.dead_at}` : " — ВЫЖИЛ"}`);
  console.log(`${"─".repeat(120)}`);

  console.log(
    pad("Spr", 5) + pad("Phase", 14) + pad("Team", 12) +
    pad("Bugs", 6) +
    pad("Feat", 6) + pad("Bug", 6) + pad("Ref", 6) +
    pad("Income", 9) + pad("Salary", 9) + pad("Rent", 7) +
    pad("Penalty", 9) + pad("Budget", 10) + pad("Debt", 8)
  );

  for (const s of result.log) {
    console.log(
      pad(s.sprint, 5) + pad(s.phase, 14) + pad(s.team_comp, 12) +
      pad(s.bugs_in, 6) +
      pad(s.features_done, 6) + pad(s.bugs_fixed, 6) + pad(s.refactor_done, 6) +
      pad(s.income, 9) + pad(s.salaries, 9) + pad(s.rent, 7) +
      pad(s.penalty, 9) + pad(s.budget, 10) + pad(s.tech_debt, 8)
    );
  }
}
