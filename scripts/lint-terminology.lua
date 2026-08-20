-- Pandoc lua filter that will "lint" a Markdown file for bad terminology.
-- E.g., this will replace certain word or phrase usages with other words or
-- phrases.

-- `sub-access` intentionally goes the other way from the closed `subindex`
-- and `subfield` compounds; confirm this against the FIRRTL grammar/ABI.
local badWords = {
   ["sub-index"] = "subindex",
   ["sub-field"] = "subfield",
   ["subaccess"] = "sub-access",
}

local badPhrases = {
   ["sub index"] = "subindex",
   ["sub field"] = "subfield",
   ["sub access"] = "sub-access",
}

local function wordParts(text)
   -- Str elements can include surrounding punctuation, e.g. "(subfield,".
   return text:match("^([^%a]*)([%a][%a'’]*)([^%a]*)$")
end

local function tokenParts(text)
   return text:match("^([^%a]*)([%a][%a%-'’]*)([^%a]*)$")
end

local inflections = { "'s", "’s", "es", "s" }

-- Look up a word, retrying with a trailing inflection ("subfields",
-- "subfield's") stripped so that the inflection carries over to the replacement.
local function lookup(table_, word)
   local lowered = word:lower()
   local replacement = table_[lowered]
   if replacement then
      return replacement
   end
   for _, suffix in ipairs(inflections) do
      local stem = lowered:sub(1, #lowered - #suffix)
      if lowered:sub(-#suffix) == suffix and table_[stem] then
         return table_[stem] .. suffix
      end
   end
   return nil
end

-- Apply the capitalization of `original` to `replacement`: an all-caps original
-- yields an all-caps replacement, a leading capital is preserved, and anything
-- else is left as written in the table.  Note that Lua's string.upper and its
-- %u/%l classes are byte-wise and locale-tainted -- they mangle the UTF-8 smart
-- apostrophe in, e.g., "SUB-FIELD’S" -- so only ASCII ranges are used here.
local function replacementCase(replacement, original)
   if original:match("[A-Z]") and not original:match("[a-z]") then
      return (replacement:gsub("[a-z]", string.upper))
   end
   if original:match("^[A-Z]") then
      return (replacement:gsub("^[a-z]", string.upper))
   end
   return replacement
end

local function fixInlines(inlines)
   local fixed = {}
   local i = 1

   while i <= #inlines do
      local elem = inlines[i]

      if elem.t == "Str" then
         local prefix, token, suffix = tokenParts(elem.text)
         local replacement = token and lookup(badWords, token)
         if replacement then
            elem.text = prefix .. replacementCase(replacement, token) .. suffix
         end

         -- A phrase is represented by Str, Space, Str in the Pandoc AST.
         local nextSpace = inlines[i + 1]
         local nextElem = inlines[i + 2]
         local firstPrefix, firstWord, firstSuffix = wordParts(elem.text)
         local secondPrefix, secondWord, secondSuffix
         if nextElem and nextElem.t == "Str" then
            secondPrefix, secondWord, secondSuffix = wordParts(nextElem.text)
         end

         local phrase = firstWord and secondWord and
            firstWord:lower() .. " " .. secondWord:lower()
         local phraseReplacement = phrase and lookup(badPhrases, phrase)
         if firstSuffix == "" and secondPrefix == "" and
            nextSpace and nextSpace.t == "Space" and phraseReplacement then
            local text = firstPrefix .. replacementCase(
               phraseReplacement, firstWord .. secondWord) .. firstSuffix .. secondSuffix
            table.insert(fixed, pandoc.Str(text))
            i = i + 3
         else
            table.insert(fixed, elem)
            i = i + 1
         end
      else
         -- Code, Math, and raw markup are left alone; Pandoc invokes Inlines
         -- for nested inline containers separately.
         table.insert(fixed, elem)
         i = i + 1
      end
   end

   return fixed
end

function Inlines(inlines)
   return fixInlines(inlines)
end
