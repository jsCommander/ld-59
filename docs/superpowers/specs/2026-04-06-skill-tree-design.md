# Skill Tree Component — Design Spec

## Overview

Переиспользуемый компонент дерева апгрейдов для `game_kit/`. Состоит из двух частей:
1. **Редактор** — `@tool` скрипт для раскладки нод по сетке в Godot Editor
2. **Рантайм** — отображение дерева в игре с pan, тултипами и сигналами наружу

Компонент не содержит игровой логики. Он отображает ноды, рисует связи, показывает тултипы и эмитит сигналы. Что апгрейд делает, можно ли его купить, хватает ли денег — решает игровой код снаружи.

## Данные

### BaseUpgrade (новый, game_kit)

Базовый ресурс в `game_kit/` — контракт данных для skill tree компонента. Компонент знает только про `BaseUpgrade`, не про игровые подклассы.

```gdscript
# game_kit/ui/components/skill_tree/base_upgrade.gd
class_name BaseUpgrade extends Resource

@export var id: String
@export var display_name: String
@export var description: String
@export var icon: Texture2D
```

Игровой `UpgradeTree` наследует от него:

```gdscript
# game_data/upgrade_tree/upgrade_tree.gd
class_name UpgradeTree extends BaseUpgrade

@export var cost: int
@export var prerequisites: Array[UpgradeTree] = []
# ... другие игровые поля
```

> **Миграция:** текущий `UpgradeTree extends BaseGameData` меняется на `extends BaseUpgrade`. Поля `id`, `display_name`, `description`, `icon` переезжают из `UpgradeTree` в `BaseUpgrade`. `BaseUpgrade` содержит `id`, поэтому наследование от `BaseGameData` не нужно — `BaseUpgrade` полностью его заменяет.

### SkillTreeNodePlacement (новый, game_kit)

Позиция одной ноды на сетке + визуальные связи (линии).

```gdscript
# game_kit/ui/components/skill_tree/skill_tree_node_placement.gd
class_name SkillTreeNodePlacement extends Resource

@export var upgrade: BaseUpgrade
@export var grid_x: int = 0
@export var grid_y: int = 0
@export var children: Array[SkillTreeNodePlacement] = []
```

- `children` — ноды, к которым от этой ноды идут линии вниз по дереву. Это **чисто визуальные связи** для отрисовки линий. Направление: от parent к children. Каждая нода хранит ссылки на своих потомков.
- Позиция `(grid_x, grid_y)` — целочисленные координаты на сетке. `(0, 0)` — центр дерева.

> **Два графа:** `SkillTreeNodePlacement.children` — визуальный граф (какие линии рисовать). `UpgradeTree.prerequisites` — логический граф (что нужно для разблокировки). Компонент в `game_kit/` знает только про визуальный граф. Логический граф — ответственность игрового кода. Редактор может опционально auto-populate `children` из `prerequisites` при размещении нод, чтобы уменьшить ручную работу.

### SkillTreeLayout (новый, game_kit)

Вся раскладка дерева — один `.tres` файл.

```gdscript
# game_kit/ui/components/skill_tree/skill_tree_layout.gd
class_name SkillTreeLayout extends Resource

@export var nodes: Array[SkillTreeNodePlacement] = []
@export var root: SkillTreeNodePlacement
@export var cell_size: int = 80
```

- `root` — стартовая нода, центр дерева. Рантайм-компонент центрирует скролл на ней.
- `cell_size` — размер ячейки сетки в пикселях. Единый источник правды для редактора и рантайма.

### NodeState (enum, game_kit)

Определён в `skill_tree_view.gd`, используется и нодами, и игровым кодом.

```gdscript
enum NodeState {
    LOCKED,
    AVAILABLE,
    PURCHASED,
}
```

## Компонент 1: Редактор (SkillTreeEditor)

`@tool` скрипт для Godot Editor. Позволяет дизайнеру визуально расставить апгрейды по сетке и настроить связи.

### Файлы

```
game_kit/ui/components/skill_tree/
  skill_tree_editor.gd
  skill_tree_editor.tscn
```

### Входные данные

```gdscript
@tool
class_name SkillTreeEditor extends Control

@export var layout: SkillTreeLayout              # ресурс, который редактируем
@export var upgrades_path: String = ""           # путь к папке с .tres ресурсами
```

### Загрузка апгрейдов

Редактор сканирует `upgrades_path` рекурсивно, загружает все `.tres` файлы, фильтрует `is BaseUpgrade`. Результат — массив доступных для размещения ресурсов.

```gdscript
func _scan_upgrades() -> Array[BaseUpgrade]:
    # ResourceLoader + DirAccess.open(upgrades_path)
    # Рекурсивно находит все .tres
    # Фильтрует по is BaseUpgrade
    # Возвращает массив
```

### UI в редакторе

**Палитра (левая панель):**
- Список всех `BaseUpgrade` ресурсов из `upgrades_path`
- Каждый элемент: иконка + `display_name`
- Уже размещённые — визуально помечены (серые / с галочкой)
- Drag из палитры начинает размещение

**Сетка (основная область):**
- Рисует сетку ячеек
- Размещённые ноды показываются как иконки апгрейдов
- Drag & drop: перетащить из палитры на ячейку = разместить
- Drag по сетке = переместить (snap to grid)
- Клик по ноде → клик по другой ноде = создать/удалить connection (child link)
- Delete/Backspace на выбранной ноде = удалить с сетки

**Валидация:**
- Запрещает размещение двух нод в одну ячейку
- Предупреждает о нодах, не достижимых из root
- Предупреждает о циклах в connections

**Сохранение:**
- Debounced auto-save: запись в ресурс через 1 секунду после последнего изменения
- `ResourceSaver.save(layout)` после debounce

## Компонент 2: Рантайм (SkillTreeView)

Отображает дерево в игре. Переиспользуемый компонент в `game_kit/`.

### Файлы

```
game_kit/ui/components/skill_tree/
  skill_tree_view.gd
  skill_tree_view.tscn
  skill_tree_node.gd
  skill_tree_node.tscn
  skill_tree_tooltip.gd
  skill_tree_tooltip.tscn
```

### Входные данные

```gdscript
class_name SkillTreeView extends Control

@export var layout: SkillTreeLayout
```

### Построение дерева

```
1. Берёт cell_size из layout.cell_size
2. Итерирует layout.nodes
3. Для каждой SkillTreeNodePlacement:
   - Создаёт SkillTreeNode (instantiate сцены)
   - Позиция: Vector2(placement.grid_x * cell_size, placement.grid_y * cell_size)
   - Передаёт placement.upgrade для отображения (иконка, имя)
4. Линии рисуются в _draw():
   - Итерирует все ноды, для каждой — её children
   - L-образная маршрутизация: горизонтальный сегмент, затем вертикальный
   - Цвет линии зависит от состояния нод (locked/unlocked)
```

### SkillTreeNode (одна нода)

```gdscript
class_name SkillTreeNode extends Control

signal clicked(upgrade: BaseUpgrade)
signal hovered(upgrade: BaseUpgrade)
signal unhovered(upgrade: BaseUpgrade)

var upgrade: BaseUpgrade
var state: SkillTreeView.NodeState = SkillTreeView.NodeState.LOCKED
```

**Визуал:**
- Ромбик (повёрнутый квадрат) с иконкой апгрейда внутри
- Три визуальных состояния:
  - `LOCKED` — тёмный, приглушённый
  - `AVAILABLE` — подсвеченный, интерактивный
  - `PURCHASED` — яркий, с рамкой/эффектом

**Взаимодействие:**
- Клик → эмитит `clicked(upgrade)`
- Mouse enter → эмитит `hovered(upgrade)`
- Mouse exit → эмитит `unhovered(upgrade)`

### API для игрового кода

```gdscript
# Установить состояние конкретной ноды (поиск по id)
func set_node_state(upgrade_id: String, state: NodeState) -> void:

# Установить состояния всех нод разом
func set_all_states(states: Dictionary[String, NodeState]) -> void:
```

> **Поиск по id, не по ссылке:** API принимает `upgrade_id: String` вместо `BaseUpgrade` ссылки. Это надёжнее — не зависит от того, один ли и тот же Resource instance используется в разных местах.

Игровой код подписывается на сигналы и управляет состояниями:

```gdscript
# Пример использования в игровом коде
func _ready() -> void:
    skill_tree_view.node_clicked.connect(_on_upgrade_clicked)

func _on_upgrade_clicked(upgrade: BaseUpgrade) -> void:
    var ut: UpgradeTree = upgrade as UpgradeTree
    if can_afford(ut) and prerequisites_met(ut):
        purchase(ut)
        skill_tree_view.set_node_state(ut.id, SkillTreeView.NodeState.PURCHASED)
```

### Сигналы

```gdscript
signal node_clicked(upgrade: BaseUpgrade)
signal node_hovered(upgrade: BaseUpgrade)
signal node_unhovered(upgrade: BaseUpgrade)
```

### Тултип

Встроенный `SkillTreeTooltip` — `PanelContainer`, позиционируется рядом с нодой внутри компонента (без `UiPopupManager`, т.к. он принимает `Node2D`, а наши ноды — `Control`).

Содержимое тултипа:
- **Название** (`display_name`)
- **Описание** (`description`)
- **Иконка**

Для кастомного контента (стоимость, кнопка "Upgrade") — игровой код подписывается на `node_clicked` / `node_hovered` и показывает свой UI.

При клике на пустую область или другую ноду — тултип закрывается.

### Pan (перемещение камеры)

- Правая кнопка мыши зажата + drag = перемещение всего дерева
- Реализация: смещение `_pan_offset: Vector2`, применяется ко всем дочерним нодам
- Центрируется на `layout.root` при открытии
- Правый клик перехватывается компонентом (stop propagation)

### Линии между нодами

- Только горизонтальные и вертикальные сегменты, без диагоналей
- Если parent и child не на одной оси — L-образная маршрутизация: горизонтальный сегмент от parent, затем вертикальный до child
- Цвета линий:
  - Оба конца `PURCHASED` → яркий цвет (unlocked)
  - Иначе → приглушённый цвет (locked)

### Логирование

```gdscript
Log.log_info(self.name, "Skill tree built: %d nodes" % layout.nodes.size())
Log.log_debug(self.name, "Node state changed: %s -> %s" % [upgrade_id, state])
Log.log_debug(self.name, "Node clicked: %s" % upgrade.display_name)
```

## Структура файлов — итог

```
game_kit/
  ui/components/
    skill_tree/
      base_upgrade.gd              # Resource — контракт данных (id, name, desc, icon)
      skill_tree_layout.gd         # Resource — раскладка дерева (массив нод + cell_size)
      skill_tree_node_placement.gd # Resource — позиция одной ноды + children (визуальные связи)
      skill_tree_view.gd           # Control — рантайм отображение + NodeState enum
      skill_tree_view.tscn
      skill_tree_node.gd           # Control — одна нода (ромбик с иконкой)
      skill_tree_node.tscn
      skill_tree_tooltip.gd        # PanelContainer — тултип при клике
      skill_tree_tooltip.tscn
      skill_tree_editor.gd         # @tool Control — редактор для Godot Editor
      skill_tree_editor.tscn

game_data/
  upgrade_tree/
    upgrade_tree.gd                # extends BaseUpgrade (миграция с BaseGameData)
    *.tres                         # конкретные апгрейды
```

## Миграция существующего кода

Текущие файлы, которые будут заменены новым компонентом:
- `components/upgrade_tree/upgrade_tree_view.gd` → заменяется `game_kit/.../skill_tree_view.gd`
- `components/upgrade_tree/upgrade_tree_node.gd` → заменяется `game_kit/.../skill_tree_node.gd`
- `game_data/upgrade_tree/upgrade_tree.gd` → меняет базовый класс на `BaseUpgrade`

Текущий `UpgradeTreeView` берёт апгрейды из `DR` (DataRegistry) и строит радиальный layout автоматически. Новый `SkillTreeView` берёт готовый `SkillTreeLayout` ресурс — layout задан дизайнером в редакторе.

Текущий `UpgradeTreeNode` зависит от `PD` (PlayerData) для состояний. Новый `SkillTreeNode` получает состояние снаружи через API — никаких зависимостей от автолоадов.
