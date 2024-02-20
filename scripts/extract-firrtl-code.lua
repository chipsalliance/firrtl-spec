index = 0

-- Return the indices of all strings in `text` that are between `snippetbegin`
-- and `snippetend` strings.
function getSnippets (text)
   local foundSnippet = false
   local i = 0
   local start
   local snippets = {}
   while true do
      if start == nil then
         _, i = string.find(text, "snippetbegin.-\n", i + 1)
         if i == nil then
            break
         end
         -- Increment by one to drop the newline from the snippet.
         start = i + 1
         -- Decrement 'i' so that there is _always_ a newline for the match in
         -- the else block to use.  This makes it possible to match emtpy
         -- snippets easily as they look exactly like non-empty snippets.
         i = i - 1
      else
         e, i = string.find(text, "\n[^\n]-snippetend", i + 1)
         if i == nil then
            error("missing 'snippetend'")
         end
         table.insert(snippets, {i = start, e = e - 1})
         start = nil
      end
   end
   return snippets
end

function CodeBlock(elem)
   local extMap = {
      firrtl = "fir",
      verilog = "v",
      systemverilog = "sv"
   }
   local ext = extMap[elem.classes[1]]
   local skip = elem.classes[2] == "notest"

   -- Write the entire code block to a file if we know its extension and we're
   -- not told to skip testing it.
   if ext and not skip then
     local filename = string.format("build/%s-code-example-%03d.%s", PANDOC_STATE.input_files[1], index, ext)
     index = index + 1

     local f = io.open(filename, 'w')
     f:write(elem.text)
     f:write("\n")
     f:close()
   end

   local snippets = getSnippets(elem.text)

   -- If no snippets were found, return the original code block.
   if next(snippets) == nil then
      return pandoc.CodeBlock(elem.text, elem.attr)
   end

   -- Otherwise, extract all the snippets and return a new code block.
   local newtext
   for i, snippet in ipairs(snippets) do
      local a = string.sub(elem.text, snippet.i, snippet.e)
      if newtext == nil then
         newtext = a
      else
         newtext = newtext .. "\n" .. a
      end
   end

   return pandoc.CodeBlock(newtext, elem.attr)
end
