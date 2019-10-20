return {
  {
    name = "Сложение",
    level = 1,
    task = "a + b = ?",
    limit = 10,
    -- Схема читается наоборот, то есть снизу вверх.
    scheme = {
      {"task", "task", "task"},
      {"task", "task", "task"},
    }
  },
  {
    name = "Сложение",
    level = 2,
    task = "a + b = ?",
    limit = 10,
    scheme = {
      {"number", "number", "number"},
      {"number", "number", "number"},
      {"number", "      ", "number"},
    }
  },
  {
    name = "Сложение",
    level = 3,
    task = "a + ? = b",
    limit = 10,
    scheme = {
      {"task", "task", "task"},
      {"task", "task", "task"},
      {"task", "task", "task"},
    }
  },
  {
    name = "Сложение",
    level = 4,
    task = "a + ? = b",
    limit = 20,
    scheme = {
      {"task", "task", "task"},
      {"task", "task", "task"},
    }
  },
  {
    name = "Сложение",
    level = 5,
    task = "a + b = ?",
    limit = 50,
    scheme = {
      {"task", "task", "task"},
      {"task", "task", "task"},
      {"task", "task", "task"},
    }
  },
  {
    name = "Сложение",
    level = 6,
    task = "a + b = ?",
    limit = 50,
    scheme = {
      {"number", "number", "number"},
      {"number", "number", "number"},
      {"number", "number", "number"},
    }
  },
  {
    name = "Сложение",
    level = 7,
    task = "a + b = ?",
    limit = 100,
    scheme = {
      {"number", "number", "number"},
      {"number", "number", "number"},
      {"number", "number", "number"},
    }
  },
  {
    name = "Сложение",
    level = 8,
    task = "a + b = ?",
    limit = 100,
    scheme = {
      {"task", "task", "task"},
      {"task", "task", "task"},
      {"task", "task", "task"},
      {"task", "    ", "task"},
    }
  },
  {
    name = "Сложение",
    level = 9,
    task = "a + b = ?",
    limit = 200,
    scheme = {
      {"number", "number", "number"},
      {"number", "number", "number"},
      {"number", "number", "number"},
      {"number", "number", "       "},
    }
  },
  {
    name = "Тест",
    level = 1,
    task = "a + ? = b",
    limit = 10,
    scheme = {
      {"", "task", ""},
    }
  }
}