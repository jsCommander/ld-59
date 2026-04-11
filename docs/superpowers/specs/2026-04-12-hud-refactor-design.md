# HUD Refactor: Decomposition + Layout Rework

## Overview

Разбиваем монолитный HUD на мелкие автономные компоненты и перекраиваем лейаут: капитализация с XP баром и таймером наверху, спринт с карточками задач внизу. Попапы переезжают из уровней в HUD.

## Текущее состояние

Один `hud.gd` (~150 строк) рулит всем: таймер, капитализация, XP бар, company label, карточки задач, спринт инфо. Все сигналы подписаны в одном месте, вся логика обновления UI в одном скрипте.

Попапы (`UiUpgradeChoice`, `UiHireChoice`, `UiGameOver`) живут как дети уровня, хотя уровень их не трогает — они сами подписаны на `SB` и сами управляют видимостью. `popup_manager.gd` — отдельная прослойка поверх `UiPopupManager` только для developer popup.

## Новый лейаут

### TopBar (верх экрана, одна линия)

```
[XP Bar]          [$15,000]          [10:00]
              Больше чем у Zynga! (flash ~2сек)
```

- **Лево**: XP бар — прогресс до следующего уровня
- **Центр**: Капитализация — крупный текст, доминантный элемент. Под ним company flash label, появляется на ~2 секунды при достижении milestone и исчезает
- **Право**: Таймер игры — обратный отсчёт MM:SS

### BottomBar (низ экрана, панель)

```
         Спринт 1    [████████░░░░]
  [Card1] [Card2] [Card3] [Card4] ...
```

- Спринт лейбл + таймер бар (с цветовым градиентом зелёный → жёлтый → красный)
- Горизонтальная очередь карточек задач с drag-and-drop

### CEO Commentator

Правый нижний угол, поверх всего. Без изменений.

### Попапы

`UiPopupManager` (из game_kit) сидит ребёнком HUD. HUD слушает сигналы (`level_up`, `developer_hire_requested`, `game_over`, `entity_selected`) и вызывает `show_popup()` с нужной сценой. Файл `popup_manager.gd` удаляется.

Из уровней (`base_level.tscn`, `test_level.tscn`) ноды `UiUpgradeChoice`, `UiHireChoice`, `UiGameOver` удаляются.

## Декомпозиция на компоненты

Каждый компонент — автономная сцена (.tscn + .gd), сам подписывается на сигналы из `SB`.

| Компонент | Путь | Ответственность |
|-----------|------|-----------------|
| `UiCapitalization` | `components/ui/ui_capitalization/` | Крупный текст капитализации + company flash label под ним. Слушает `SB.valuation_changed`, `SB.level_up` |
| `UiXpBar` | `components/ui/ui_xp_bar/` | Прогресс бар до следующего уровня. Слушает `SB.valuation_changed`, `SB.level_up` |
| `UiGameTimer` | `components/ui/ui_game_timer/` | Лейбл обратного отсчёта MM:SS. Слушает `SB.game_timer_changed` |
| `UiSprintPanel` | `components/ui/ui_sprint_panel/` | Спринт лейбл + таймер бар + контейнер карточек. Слушает `SB.sprint_started`, `SB.sprint_ended`, `SB.sprint_timer_changed`, `SB.task_queue_changed` |
| `UiCeoCommentator` | `components/ui/ui_ceo_commentator/` | CEO речевой пузырь в правом нижнем углу |
| `UiHud` | `components/ui/ui_hud/` | Корневой CanvasLayer. Собирает лейаут (TopBar + BottomBar). Держит preload-ы попапов и вызывает `UiPopupManager.show_popup()` по сигналам |

### Принцип

- HUD — тупой контейнер для лейаута + точка входа для попапов
- Каждый UI-компонент автономен: сам подписывается на нужные сигналы, сам обновляет себя
- Никакой логики маршрутизации данных в HUD — компоненты напрямую читают `PD` и слушают `SB`

## Что удаляется

- `components/hud/` — вся папка, всё переехало в `components/ui/`
- `UiUpgradeChoice`, `UiHireChoice`, `UiGameOver` как дети уровня — переезжают под UiHud через UiPopupManager
