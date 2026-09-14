-- {"id":1308639971,"ver":"1.0.6","libVer":"1.0.0","author":"Jobobby04 / fixed","dep":["ReadWN>=1.0.11","url>=1.0.0"]}

-- FanMTL search fix:
-- Uses FanMTL's search system instead of guessing novel URLs.
-- Returns multiple matching novels from search results.
-- Keeps ReadWN for novel/chapter parsing.

local qs = Require("url").querystring

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
    name = "FansMTL (FanMTL Search Fixed)",
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

local function addResult(results, seen, el)
    local href = el:attr("href")

    if not href or href == "" then
        return
    end

    -- Only accept actual FanMTL novel pages.
    if not href:match("/novel/") then
        return
    end

    local link = absoluteURL(href)

    if not link or seen[link] then
        return
    end

    local title = nil

    -- Try common title elements first.
    local titleEl = el:selectFirst(
        ".novel-title, .title, h3, h4"
    )

    if titleEl and not titleEl:isEmpty() then
        title = titleEl:text()
    end

    -- Fall back to anchor text.
    if not title or title == "" then
        title = el:text()
    end

    if not title or title == "" then
        return
    end

    title = title:gsub("^%s+", "")
    title = title:gsub("%s+$", "")

    if title == "" then
        return
    end

    local imageURL = nil

    local img = el:selectFirst("img")

    if img and not img:isEmpty() then
        imageURL = img:attr("src")

        if not imageURL or imageURL == "" then
            imageURL = img:attr("data-src")
        end

        imageURL = absoluteURL(imageURL)
    end

    seen[link] = true

    table.insert(results, Novel {
        title = title,
        link = link,
        imageURL = imageURL
    })
end

ext.search = function(data)
    local query = data[QUERY]
    local page = data[PAGE] or 1

    if not query or query == "" then
        return {}
    end

    -- A new FanMTL search creates a new search ID.
    -- Therefore perform the search only for the first page.
    if page ~= 1 then
        return {}
    end

    -- FanMTL uses the EmpireCMS search system.
    --
    -- Search parameters:
    -- searchget = 1
    -- keyboard  = search text
    -- show      = title
    local searchURL = qs({
        searchget = 1,
        keyboard = query,
        show = "title"
    }, "https://www.fanmtl.com/e/search/")

    local document = GETDocument(searchURL)

    if not document or document:isEmpty() then
        return {}
    end

    local results = {}
    local seen = {}

    -- FanMTL search results contain links to /novel/*.html.
    local links = document:select("a[href*='/novel/']")

    if links and not links:isEmpty() then
        for i = 0, links:size() - 1 do
            addResult(
                results,
                seen,
                links:get(i)
            )
        end
    end

    return results
end

return ext