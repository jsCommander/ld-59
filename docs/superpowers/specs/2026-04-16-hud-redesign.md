# HUD Redesign

## Summary

Редизайн HUD: тёмные панели без бордера, светлый текст, перекомпоновка элементов, приглушение семантических цветов. Одна спека покрывает токены, лейаут и цветовые фиксы — решения связаны.

## Проблемы сейчас

- Кремовый фон панелей (`SURFACE_CARD` #fff5e6) сливается с полом уровня
- Коричневый текст (`SECONDARY` #784d32) на кремовом — контраст ~4.2:1, бледно
- `FONT_COLOR` ссылается на `SECONDARY` — цвет для светлого фона, а панели теперь тёмные
- `LABEL_ON_DARK_COLOR` — отдельный вариант для тёмного фона, хотя тёмный теперь дефолт
- `RICH_TEXT_LABEL_DEFAULT_COLOR` — не используется
- Семантические цвета (FEATURE, BUG, MONEY) слишком яркие — конкурируют с золотым PRIMARY за внимание
- `HP` и `BUG` оба `SALMON` — одинаковый цвет
- `RARITY_LEGENDARY` = `DESTRUCTIVE` (красный) — конфликт семантики, legendary обычно золотой
- `PanelContainerDark` станет дубликатом дефолта после изменений — нет светлого варианта
- Кнопки: `BUTTON_DEFAULT_COLOR` = `FONT_COLOR` — после смены на кремовый будет нечитаемо на золотом фоне
- `ui_capitalization.tscn` — захардкожен яркий MONEY цвет (#00b45f), не обновится автоматически
- `SURFACE_CARD_HOVER` — осиротевший токен
- HUD лейаут: информация разбросана по углам, нет единого кластера для ключевых метрик
- CEO Comment и CEO Commentator в разных частях экрана

---

## 1. Theme Tokens

### 1.1 Панели — тёмный фон, без бордера

```gdscript
# Было:
const PANEL_CONTAINER_DEFAULT_BG: Color = SURFACE_CARD  # #fff5e6

# Стало:
const PANEL_CONTAINER_DEFAULT_BG: Color = SURFACE_DARK  # #3d2a1a
```

Бордер дефолтной панели убирается — тёмная панель и так видна на любом фоне.

### 1.2 PanelContainerDark → PanelContainerLight

Дефолт теперь тёмный, поэтому `PanelContainerDark` становится дубликатом — удалить.

Добавить `PanelContainerLight` для случаев когда нужна светлая панель:

```gdscript
# Удалить:
const PANEL_CONTAINER_DARK_BG: Color = SURFACE_DARK

# Добавить:
const PANEL_CONTAINER_LIGHT_BG: Color = SURFACE_CARD  # #fff5e6
```

Заменить все использования `PanelContainerDark` в `.tscn` файлах на дефолтный `PanelContainer`:
- `components/ui/ui_upgrade_choice/ui_upgrade_choice.tscn`
- `components/ui/ui_sprint_panel/ui_sprint_panel.tscn`
- `components/ui/ui_sprint_panel/ui_sprint_panel_label.tscn`
- `components/ui/ui_hire_choice/ui_hire_choice.tscn`

### 1.3 Текст — светлый по умолчанию

```gdscript
# Было:
const FONT_COLOR: Color = SECONDARY          # #784d32 (коричневый)
const FONT_COLOR_MUTED: Color = SECONDARY_HOVER  # #a0754f

# Стало:
const FONT_COLOR: Color = Color("#fff5e6")         # свой цвет, не ссылка на surface
const FONT_COLOR_MUTED: Color = Color("#a89880")   # приглушённый на тёмном, ~3.5:1 на SURFACE_DARK — для вторичных лейблов, не для критичной инфо
```

`LABEL_DEFAULT_COLOR` = `FONT_COLOR` — обновится автоматически.

Комментарий в коде: `FONT_COLOR` намеренно не ссылается на `SURFACE_CARD`, чтобы цвета шрифта и поверхностей могли меняться независимо.

### 1.4 Кнопки — белый текст на золотом

```gdscript
# Было:
const BUTTON_DEFAULT_COLOR: Color = FONT_COLOR  # коричневый → стал бы кремовым, нечитаемо на золотом

# Стало:
const BUTTON_DEFAULT_COLOR: Color = FONT_COLOR_ON_ACCENT  # белый (#ffffff)
```

Кремовый текст на золотом фоне — контраст ~1.3:1, нечитаемо. Белый с обводкой (`FONT_COLOR_ON_ACCENT`) решает проблему.

### 1.5 Семантические цвета — приглушить ~25%

```gdscript
# Было:
const FEATURE: Color = SKY       # #76adff
const BUG: Color = SALMON        # #ff826f
const MONEY: Color = TEAL        # #00ab70

# Стало (снижена насыщенность ~25%):
const FEATURE: Color = Color("#8fb8d9")
const BUG: Color = Color("#d9998f")
const MONEY: Color = Color("#5a9980")
```

Золотой `PRIMARY` (#ffc752) остаётся единственным ярким акцентом.

Также обновить `font_color` на Label-ноде в `components/ui/ui_capitalization/ui_capitalization.tscn` (хранится как Godot Color floats, ~#00b45f) — заменить на новый `MONEY` цвет.

### 1.6 HP = BUG

```gdscript
# Было:
const HP: Color = SALMON  # яркий, тот же что BUG

# Стало:
const HP: Color = BUG  # #d9998f (приглушённый, как BUG)
```

HP — атрибут таски, визуально не нужно отличать от BUG-цвета.

### 1.7 Rarity Legendary — золотой вместо красного

```gdscript
# Было:
const RARITY_LEGENDARY: Color = DESTRUCTIVE  # #e63333 (красный)

# Стало:
const RARITY_LEGENDARY: Color = PRIMARY  # #ffc752 (золотой)
```

Примечание: `PANEL_CONTAINER_RARITY_LEGENDARY_BG` и `BUTTON_DEFAULT_BG` оба станут золотыми — возможен визуальный конфликт легендарных карточек с кнопками. Оценить при имплементации.

### 1.8 Удалить

Из `theme_tokens.gd`:
- `LABEL_ON_DARK_COLOR` — дублирует новый дефолт `LABEL_DEFAULT_COLOR`
- `RICH_TEXT_LABEL_DEFAULT_COLOR` — не используется
- `PANEL_CONTAINER_DARK_BG` — дублирует новый дефолт
- `SURFACE_CARD_HOVER` — осиротел, нигде не используется кроме токенов

Из `ui_game_theme.tres`:
- `LabelOnDark` тема-вариация — удалить
- `RichTextLabel/colors/default_color` — обновить на новый `FONT_COLOR` (#fff5e6)
- `PanelContainerDark` тема-вариация — заменить на `PanelContainerLight`

Перед удалением `LABEL_ON_DARK_COLOR`: найти все использования и заменить на `LABEL_DEFAULT_COLOR`.

### 1.9 Синхронизация

Порядок:
1. Обновить `resources/ui_game_theme.tres` с новыми цветами (включая `RichTextLabel/colors/default_color` → #fff5e6)
2. Удалить токены из `theme_tokens.gd`
3. Прогнать `resources/validate_theme.gd`

---

## 2. HUD Layout

### 2.1 Текущий лейаут

```
┌──────────────────────────────────────┐
│ XpBar              GameTimer         │
│ (top-left)         (top-right)       │
│                                      │
│       Capitalization                 │
│       (top-center)                   │
│                                      │
│            ЦЕНТР                     │
│                                      │
│ SprintPanel          CeoComment      │
│ UpgradeButton        CeoCommentator  │
│ SprintLabel          (bottom-right)  │
│ (bottom-left)                        │
└──────────────────────────────────────┘
```

### 2.2 Новый лейаут

```
┌───────────────────────────────────────────────┐
│ Time left  3:42   $1,234,567     Commentator  │
│ Next level █████░░  Bigger than X!    Comment  │
│ Level 5  Sprint 3                              │
│                                                │
│                   ЦЕНТР                        │
│                 (геймплей)                      │
│                                                │
│ [ Sprint panel ][ Upgrade button ]             │
└───────────────────────────────────────────────┘
```

### 2.3 Изменения в `ui_hud.tscn`

**Top-left — вертикальный кластер (VBoxContainer):**
1. **Time left** — лейбл + значение, самый крупный (H3)
2. **Next level** — лейбл + прогресс-бар (бывший UiXpBar)
3. **Level + Sprint** — одна строка, мелкий текст (FONT_SIZE_DEFAULT)

Все элементы с явными лейблами.

**Top-center:**
- `UiCapitalization` — остаётся
- Добавить milestone-лейбл "Bigger than X!" под капитализацией

### 2.4 Milestone-лейбл

Milestone-данные (`MILESTONE_COMMENTS`) сейчас живут в `UiCeoComment`. Изменения:

- Добавить Label-ноду как дочерний элемент `UiCapitalization` (под суммой)
- `UiCapitalization` слушает `SB.valuation_changed`, сравнивает с порогами и обновляет лейбл
- Milestone-логику удалить из `UiCeoComment` — CEO больше не дублирует milestones
- Формат текста: "Bigger than {company_name}!"
- Если капитализация ниже первого порога — лейбл скрыт

**Top-right:**
- `UiCeoCommentator` — переезжает из bottom-right
- `UiCeoComment` — переезжает из bottom-right, рядом с комментатором

**Bottom-left — HBoxContainer:**
- `UiSprintPanel` + `UiUpgradeButton` в общем HBox
- `UiSprintLabel` — уходит в top-left кластер (Level/Sprint строка)

**Переезжают:**
- `UiGameTimer` → top-left кластер
- `UiCeoComment` → top-right
- `UiCeoCommentator` → top-right

---

## 3. Что НЕ меняем

- Sprint panel внутренности (10 карточек, TaskCard, анимация)
- Dialog system (upgrade choice, hire choice, game over)
- Upgrade button логика (пульсация, счётчик)
- SignalBus связи
- `validate_theme.gd` — только прогоняем после изменений
- `FONT_COLOR_ON_ACCENT` / `FONT_COLOR_ON_ACCENT_OUTLINE` / `FONT_COLOR_ON_ACCENT_SHADOW`
- `SURFACE_CARD` как цвет — остаётся, используется в `PanelContainerLight`
- Кнопочные бордеры (`SECONDARY`) — остаются как есть
