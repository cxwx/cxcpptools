-- Generate by GPT(GEMINI):
-- TODO: to snippet
local M = {}
local function get_node_at_cursor(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]
  local parser = vim.treesitter.get_parser(bufnr, "cpp")
  if not parser then
    vim.notify("not Treesitter parser，please install cpp parser")
    return
  end
  local tree = parser:parse()[1]
  local root = tree:root()
  return root:named_descendant_for_range(row, col, row, col)
end

function M.generate_getter_setter()
  local bufnr = vim.api.nvim_get_current_buf()
  local node = get_node_at_cursor(bufnr)
  if not node then
    return
  end

  -- 向上找到 field_declaration
  local field_node = node
  while field_node do
    local t = field_node:type()
    if t == "field_declaration" or t == "field_declarator" then
      break
    end
    field_node = field_node:parent()
  end
  if not field_node then
    vim.notify("cursor not on members")
    return
  end

  -- 类型
  local type_node = field_node:field("type")[1]
  local name_node = field_node:field("declarator")[1] or field_node:field("name")[1]
  if not type_node or not name_node then
    vim.notify("not known var name")
    return
  end
  local type_text = vim.treesitter.get_node_text(type_node, bufnr)
  local name_text = vim.treesitter.get_node_text(name_node, bufnr)

  -- 构造 getter/setter
  local getter = string.format("  [[nodiscard]] auto get_%s() const -> %s { return %s; }", name_text, type_text, name_text)
  local setter = string.format("  void set_%s(const %s& val) { %s = val; }", name_text, type_text, name_text)

  -- 找 class 节点
  local class_node = field_node
  while class_node do
    if class_node:type() == "class_specifier" then
      break
    end
    class_node = class_node:parent()
  end
  if not class_node then
    print("class not found")
    return
  end

  -- 找 public: 行
  local public_line
  for child in class_node:iter_children() do
    if child:type() == "access_specifier" then
      local text = vim.treesitter.get_node_text(child, bufnr)
      if text:match("public") then
        public_line = child:end_()
        break
      end
    end
  end

  local insert_line
  if public_line then
    insert_line = public_line
  else
    insert_line = class_node:start() + 1
    vim.api.nvim_buf_set_lines(bufnr, insert_line, insert_line, false, { " public:" })
    insert_line = insert_line + 1
  end

  -- 插入 getter/setter
  vim.api.nvim_buf_set_lines(bufnr, insert_line, insert_line, false, { getter, setter })
  print("生成 getter/setter:", name_text)
end

function M.setup()
end

-- vim.api.nvim_create_user_command("CppGenGetterSetter", M.generate_getter_setter, {})

return M
