extends Window

var _viewport: SubViewport = null
var _mesh: MeshInstance3D = null
var _info_label: Label = null
var _game: Node = null

func setup(game: Node) -> void:
    _game = game
    title = "Персонаж"
    size = Vector2i(450, 550)
    position = Vector2i(100, 100)
    
    # Основной контейнер
    var vbox: VBoxContainer = VBoxContainer.new()
    vbox.size = size
    add_child(vbox)
    
    # SubViewport для 3D сцены
    _viewport = SubViewport.new()
    _viewport.size = Vector2i(450, 350)
    _viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    _viewport.transparent_bg = true
    vbox.add_child(_viewport)
    
    # Камера
    var camera: Camera3D = Camera3D.new()
    camera.position = Vector3(0, 1.2, 3)
    camera.look_at(Vector3(0, 0.8, 0))
    _viewport.add_child(camera)
    
    # Свет
    var light: DirectionalLight3D = DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-45, 45, 0)
    light.light_energy = 1.2
    _viewport.add_child(light)
    
    var ambient: WorldEnvironment = WorldEnvironment.new()
    var env: Environment = Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.15, 0.18, 0.25)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.4, 0.4, 0.5)
    env.ambient_light_energy = 0.5
    ambient.environment = env
    _viewport.add_child(ambient)
    
    # Загрузка модели
    _mesh = _load_character_model()
    if _mesh:
        _viewport.add_child(_mesh)
    
    # TextureRect для отображения 3D
    var texture_rect: TextureRect = TextureRect.new()
    texture_rect.texture = _viewport.get_texture()
    texture_rect.custom_minimum_size = Vector2(450, 350)
    texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    vbox.add_child(texture_rect)
    
    # Информация о персонаже
    _info_label = Label.new()
    _info_label.text = _get_character_info()
    _info_label.add_theme_font_size_override("font_size", 14)
    _info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
    vbox.add_child(_info_label)
    
    # Кнопка закрытия
    var close_button: Button = Button.new()
    close_button.text = "Закрыть"
    close_button.pressed.connect(func(): hide())
    vbox.add_child(close_button)

func _load_character_model() -> MeshInstance3D:
    var file_path: String = "res://mods/1-in-8-billion/models/character.json"
    var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
    if not file:
        print("Не удалось открыть файл модели: " + file_path)
        return null
    
    var json_text: String = file.get_as_text()
    file.close()
    
    var model_data: Variant = JSON.parse_string(json_text)
    if not model_data is Dictionary:
        print("Ошибка парсинга JSON модели")
        return null
    
    return Pax.voxel.model(model_data)

func _get_character_info() -> String:
    if not _game:
        return ""
    
    var name_val: String = Pax.state.value(_game.model.features, "character_name")
    var age: int = Pax.state.value(_game.model.features, "character_age")
    var profession: String = Pax.state.value(_game.model.features, "character_profession")
    var health: int = Pax.state.value(_game.model.features, "character_health")
    var happiness: int = Pax.state.value(_game.model.features, "character_happiness")
    var money: int = Pax.state.value(_game.model.features, "character_money")
    var city: String = Pax.state.value(_game.model.features, "character_city")
    var skills: int = Pax.state.value(_game.model.features, "character_skills")
    var relationships: int = Pax.state.value(_game.model.features, "character_relationships")
    var career: int = Pax.state.value(_game.model.features, "character_career")
    var alive: bool = Pax.state.value(_game.model.features, "character_alive")
    
    if not alive:
        return "💀 " + name_val + " умер в возрасте " + str(age) + " лет."
    
    return "👤 %s\n📍 %s\n🎂 Возраст: %d\n💼 Профессия: %s (уровень %d)\n💰 Деньги: %d₽\n❤️ Здоровье: %d%%\n😊 Счастье: %d%%\n🤝 Отношения: %d%%\n📚 Навыки: %d" % [
        name_val, city, age, profession, career, money, health, happiness, relationships, skills
    ]

func _process(_delta: float) -> void:
    # Обновляем информацию каждые 30 кадров
    if _info_label and _game and Engine.get_frames_drawn() % 30 == 0:
        _info_label.text = _get_character_info()