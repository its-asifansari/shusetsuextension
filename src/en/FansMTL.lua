-- {"id":1308639971,"ver":"1.0.5","libVer":"1.0.0","author":"Jobobby04 / fixed","dep":["ReadWN>=1.0.11"]}

local GENRES = {
    "All", "Action", "Adventure", "Comedy", "Contemporary Romance", "Drama",
    "Eastern Fantasy", "Ecchi", "Fantasy", "Fantasy Romance", "Gender Bender",
    "Harem", "Historical", "Horror", "Josei", "Lolicon", "Magical Realism",
    "Martial Arts", "Mecha", "Mystery", "Psychological", "Romance", "School Life",
    "Sci-fi", "Seinen", "Shoujo", "Shounen", "Shounen Ai", "Slice of Life",
    "Smut", "Sports", "Supernatural", "Tragedy", "Video Games", "Wuxia",
    "Xianxia", "Xuanhuan", "Yaoi", "Fan-Fiction", "Urban", "Virtual Reality",
    "Faloo", "Korean",
}

local ext = Require("ReadWN")("https://www.fanmtl.com", {
    id = 1308639971,
    name = "FansMTL",
    imageURL = "https://jobobby04.github.io/ShosetsuExtensions/master/icons/fans_mtl.png",
    shrinkURLNovel = "^.-fanmtl%.com",
    hasCloudFlare = true,
    genres = GENRES,

    listingsMap = {
        {
            name = "Recently Added Chapters",
            increments = false,
            selector = "#latest-updates .novel-list.grid.col .novel-item a",
            url = function(data)
                return "https://www.fanmtl.com"
            end
        },

        {
            name = "Popular Daily Updates",
            increments = true,
            url = function(data)
                return "https://www.fanmtl.com/list/all/all-lastdotime-" ..
                    (data[PAGE] - 1) .. ".html"
            end
        },

        {
            name = "Most Popular",
            increments = true,
            url = function(data)
                return "https://www.fanmtl.com/list/all/all-onclick-" ..
                    (data[PAGE] - 1) .. ".html"
            end
        },

        {
            name = "New to Web Novels",
            increments = true,
            url = function(data)
                return "https://www.fanmtl.com/list/all/all-newstime-" ..
                    (data[PAGE] - 1) .. ".html"
            end
        }
    },
})


-- URL encode the search text ourselves.
-- This avoids depending on the optional "url" library.
local function urlEncode(str)
    str = tostring(str)

    return str:gsub("([^%w%-_%.~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
end


local function absoluteURL(url)
    if not url or url == "" then
        return nil
    end

    if url:match("^https?://") then
        return url
    end

    if url:sub(1, 1) == "/" then
        return "https://www.fanmtl.com" .. url
    end

    return "https://www.fanmtl.com/" .. url
end


local function makeNovel(el)
    local href = el:attr("href")

    if not href or href == "" then
        return nil
    end

    if not href:match("/novel/") then
        return nil
    end

    local link = absoluteURL(href)

    if not link then
        return nil
    end

    local titleEl = el:selectFirst(".novel-title")

    local title

    if titleEl then
        title = titleEl:text()
    end

    if not title or title == "" then
        title = el:text()
    end

    if not title or title == "" then
        return nil
    end

    title = title:gsub("^%s+", "")
    title = title:gsub("%s+$", "")

    if title == "" then
        return nil
    end

    local imageURL

    local img = el:selectFirst("img")

    if img then
        imageURL = img:attr("src")

        if not imageURL or imageURL == "" then
            imageURL = img:attr("data-src")
        end

        if imageURL and imageURL ~= "" then
            imageURL = absoluteURL(imageURL)
        end
    end

    return Novel {
        title = title,
        link = link,
        imageURL = imageURL
    }
end


ext.search = function(data)

    local query = data[QUERY]

    if not query or query == "" then
        return {}
    end

    -- FanMTL uses EmpireCMS search.
    local searchURL =
        "https://www.fanmtl.com/e/search/" ..
        "?searchget=1" ..
        "&keyboard=" .. urlEncode(query) ..
        "&show=title"

    local document = GETDocument(searchURL)

    if not document then
        return {}
    end

    local links = document:select("a[href*='/novel/']")

    if not links then
        return {}
    end

    local results = {}
    local seen = {}

    -- Use the collection's map() API instead of get()/size()
    -- or mapNotNil(), which varies between Shosetsu library versions.
    local parsed = map(links, function(el)

        local novel = makeNovel(el)

        if not novel then
            return nil
        end

        if seen[novel.link] then
            return nil
        end

        seen[novel.link] = true

        return novel
    end)

    for _, novel in ipairs(parsed) do
        if novel then
            table.insert(results, novel)
        end
    end

    return results
end


return ext