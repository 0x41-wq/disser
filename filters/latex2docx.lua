-- filters/latex2docx.lua
-- Basic Pandoc Lua filter for converting some raw LaTeX fragments to a
-- docx-friendly Pandoc AST before exporting.
--
-- Usage:
--   pandoc --lua-filter=filters/latex2docx.lua --from=latex+raw_tex -o document.docx

local pandoc = require('pandoc')

local function inline_from_markdown(md)
  local doc = pandoc.read(md, 'markdown')
  if doc and doc.blocks and #doc.blocks == 1 then
    local block = doc.blocks[1]
    if block.t == 'Para' or block.t == 'Plain' then
      return block.content
    end
  end
  return nil
end

local function convert_raw_inline(el)
  if el.format ~= 'latex' then
    return nil
  end

  local text = el.text
  -- Простые преобразования LaTeX команд в markdown-подобный текст.
  local repl = text
    :gsub('\\textbf%s*%{(.-)%}', '**%1**')
    :gsub('\\textit%s*%{(.-)%}', '*%1*')
    :gsub('\\emph%s*%{(.-)%}', '*%1*')
    :gsub('\\texttt%s*%{(.-)%}', '`%1`')
    :gsub('\\underline%s*%{(.-)%}', '%1')
    :gsub('\\href%s*%{(.-)%}%s*%{(.-)%}', '[%2](%1)')
    :gsub('\\cite%s*%{(.-)%}', '[%1]')
    :gsub('\\ref%s*%{(.-)%}', '%1')

  return inline_from_markdown(repl)
end

local function convert_raw_block(el)
  if el.format ~= 'latex' then
    return nil
  end

  local text = el.text
  if text:match('^\\begin%s*%{verbatim%}') then
    local code = text:match('\\begin%s*%{verbatim%}(.-)\\end%s*%{verbatim%}')
    if code then
      return pandoc.CodeBlock(code)
    end
  end

  -- Если не распознано, оставляем как обычный параграф текста.
  return pandoc.Para({pandoc.Str(text)})
end

return {
  { RawInline = convert_raw_inline },
  { RawBlock = convert_raw_block },
}
