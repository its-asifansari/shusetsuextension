-- {"id":1308639971,"ver":"1.0.5","libVer":"1.0.0","author":"Jobobby04 / fixed","dep":["ReadWN>=1.0.11","url>=1.0.0"]}

-- FanMTL search fix
--
-- Uses FanMTL's search system instead of guessing novel URLs.
-- Returns multiple matching novels.
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


------------------------------------------------------------
-- Convert FanMTL relative URLs into absolute URLs
------------------------------------------------------------

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


------------------------------------------------------------
-- Parse one search result
------------------------------------------------------------

local function parseSearchResult(el, seen)

    local href = el:attr("href")

    if not href or href == "" then
        return nil
    end

    -- Only accept actual novel pages.
    if not href:match("/novel/") then
        return nil
    end

    local link = absoluteURL(href)

    if not link then
        return nil
    end

    -- Remove duplicates.
    if seen[link] then
        return nil
    end

    --------------------------------------------------------
    -- Title
    --------------------------------------------------------

    local titleEl = el:selectFirst(
        ".novel-title, .title, h3, h4"
    )

    local title

    if titleEl then
        title = titleEl:text()
    end

    -- Fallback to anchor text.
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


    --------------------------------------------------------
    -- Cover image
    --------------------------------------------------------

    local imageURL = nil

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


    --------------------------------------------------------
    -- Mark URL as seen
    --------------------------------------------------------

    seen[link] = true


    --------------------------------------------------------
    -- Return Shosetsu Novel
    --------------------------------------------------------

    return Novel {
        title = title,
        link = link,
        imageURL = imageURL
    }
end


------------------------------------------------------------
-- SEARCH
------------------------------------------------------------

ext.search = function(data)

    local query = data[QUERY]

    local page = data[PAGE] or 1

    if not query or query == "" then
        return {}
    end

    --------------------------------------------------------
    -- A new FanMTL search generates a search ID.
    --
    -- For now the search itself is performed on page 1.
    --------------------------------------------------------

    if page ~= 1 then
        return {}
    end


    --------------------------------------------------------
    -- FanMTL / EmpireCMS search request
    --
    -- searchget = 1
    -- keyboard  = search text
    -- show      = title
    --------------------------------------------------------

    local searchURL = qs(
        {
            searchget = 1,
            keyboard = query,
            show = "title"
        },
        "https://www.fanmtl.com/e/search/"
    )


    --------------------------------------------------------
    -- Fetch search results
    --------------------------------------------------------

    local document = GETDocument(searchURL)

    if not document then
        return {}
    end


    --------------------------------------------------------
    -- Find novel links
    --------------------------------------------------------

    local links = document:select(
        "a[href*='/novel/']"
    )

    if links:isEmpty() then
        return {}
    end


    --------------------------------------------------------
    -- Parse results
    --------------------------------------------------------

    local seen = {}

    local results = mapNotNil(
        links,
        function(el)
            return parseSearchResult(el, seen)
        end
    )


    return results
end


return ext