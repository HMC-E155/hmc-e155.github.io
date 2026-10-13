-- Renders the course schedule table from _schedule.yml at the project root.
-- Usage: {{< schedule >}}

local function read_schedule()
  local path = pandoc.path.join({ quarto.project.directory, "_schedule.yml" })
  local f = assert(io.open(path, "r"), "could not open " .. path)
  local yaml = f:read("a")
  f:close()
  -- Let pandoc parse the YAML so string values are read as Markdown.
  return pandoc.read("---\n" .. yaml .. "\n---\n", "markdown").meta
end

local function cell(value)
  if value == nil then
    return {}
  end
  return { pandoc.Plain(value) }
end

local function monday_of_week(first_monday, week)
  local y, m, d = pandoc.utils.stringify(first_monday):match("^(%d+)-(%d+)-(%d+)$")
  assert(y, "first-monday must be formatted YYYY-MM-DD")
  -- os.time normalizes the day overflow; noon avoids DST edge cases.
  local t = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d) + 7 * (week - 1), hour = 12 })
  local date = os.date("*t", t)
  return date.month .. "/" .. date.day
end

return {
  ["schedule"] = function()
    local schedule = read_schedule()
    local headers = {}
    for i, h in ipairs({ "Week #", "Monday Date", "Tuesday's Class", "Thursday's Class", "Due" }) do
      headers[i] = cell(pandoc.Inlines(h))
    end

    local rows = {}
    for week, entry in ipairs(schedule.weeks) do
      table.insert(rows, {
        cell(pandoc.Inlines(tostring(week))),
        cell(pandoc.Inlines(monday_of_week(schedule["first-monday"], week))),
        cell(entry.tue),
        cell(entry.thu),
        cell(entry.due),
      })
    end

    local aligns = {}
    local widths = {}
    for i = 1, #headers do
      aligns[i] = pandoc.AlignCenter
      widths[i] = 0
    end

    local simple = pandoc.SimpleTable({}, aligns, widths, headers, rows)
    return pandoc.utils.from_simple_table(simple)
  end,
}
