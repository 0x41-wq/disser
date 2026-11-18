-- cleanup-latex.lua
-- Pandoc Lua filter to handle custom LaTeX commands and fix common issues

function RawBlock(el)
  if el.format ~= 'latex' and el.format ~= 'tex' then
    return el
  end
  
  local content = el.text
  
  -- Remove \addcontentsline commands (not needed for DOCX)
  content = content:gsub('\\addcontentsline%b{}', '')
  
  -- Remove or replace custom defined commands that might cause issues
  content = content:gsub('\\formbytotal%b{}', '')
  content = content:gsub('\\totalfigures%b{}', '')
  content = content:gsub('\\totaltables%b{}', '')
  
  -- Handle \input commands - remove them if not resolvable
  content = content:gsub('\\input%b{}', '')
  
  -- Remove \include commands
  content = content:gsub('\\include%b{}', '')
  
  if content ~= el.text then
    el.text = content
  end
  
  return el
end

function RawInline(el)
  if el.format ~= 'latex' and el.format ~= 'tex' then
    return el
  end
  
  local content = el.text
  
  -- Remove custom commands that cause issues
  content = content:gsub('\\formbytotal%b{}', '')
  content = content:gsub('\\actualityTXT', 'актуальность')
  content = content:gsub('\\progressTXT', 'прогресс')
  content = content:gsub('\\aimTXT', 'цель')
  content = content:gsub('\\tasksTXT', 'задачи')
  content = content:gsub('\\noveltyTXT', 'новизна')
  content = content:gsub('\\influenceTXT', 'влияние')
  content = content:gsub('\\methodsTXT', 'методы')
  content = content:gsub('\\defpositionsTXT', 'положения')
  content = content:gsub('\\reliabilityTXT', 'надежность')
  content = content:gsub('\\probationTXT', 'апробация')
  content = content:gsub('\\contributionTXT', 'вклад')
  content = content:gsub('\\publicationsTXT', 'публикации')
  
  if content ~= el.text then
    el.text = content
  end
  
  return el
end

function Str(el)
  -- Handle undefined references and other problematic content
  return el
end
