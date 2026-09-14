-- {"id":1308639971,"ver":"1.0.2","libVer":"1.0.0","author":"Jobobby04 / fixed","dep":["ReadWN>=1.0.11"]}
-- FanMTL fix:
-- 1) Uses fanmtl.com instead of the obsolete fansmtl.com domain.
-- 2) Adds a direct slug fallback because FanMTL's old /e/search/ endpoint
--    currently returns 404. This lets Shosetsu find title-based URLs directly.

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

local base = Require("ReadWN")("https://www.fanmtl.com", {
    id = 1308639971,
    name = "FansMTL (FanMTL Fixed)",
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
                return "https://www.fanmtl.com/list/all/all-lastdotime-" .. (data[PAGE] - 1) .. ".html"
            end
        },
        {
            name = "Most Popular",
            increments = true,
            url = function(data)
                return "https://www.fanmtl.com/list/all/all-onclick-" .. (data[PAGE] - 1) .. ".html"
            end
        },
        {
            name = "New to Web Novels",
            increments = true,
            url = function(data)
                return "https://www.fanmtl.com/list/all/all-newstime-" .. (data[PAGE] - 1) .. ".html"
            end
        }
    },
})

local function slugify(s)
    s = s:lower()
    s = s:gsub("&", " and ")
    s = s:gsub("[^%w%s%-]", "")
    s = s:gsub("%s+", "-")
    s = s:gsub("%-+", "-")
    s = s:gsub("^%-", ""):gsub("%-$", "")
    return s
end

local function directNovel(query)
    local slug = slugify(query)
    if slug == "" then
        return {}
    end

    local url = "/novel/" .. slug .. ".html"
    local ok, document = pcall(function()
        return GETDocument(base.baseURL .. url)
    end)

    if not ok or document == nil then
        return {}
    end

    local titleElem = document:selectFirst(".novel-header .novel-info h1")
    if titleElem == nil then
        return {}
    end

    local imageURL = ""
    local img = document:selectFirst(".novel-header .fixed-img .cover img")
    if img ~= nil then
        local src = img:attr("data-src")
        if src ~= nil then
            imageURL = base.baseURL .. src
        end
    end

    return {
        Novel {
            title = titleElem:text(),
            link = url,
            imageURL = imageURL
        }
    }
end

-- FanMTL's old POST search endpoint is no longer reliable. Try the site's
-- title-derived URL first; this also fixes the specific novel that motivated
-- this extension.
base.search = function(self, filters)
    local query = filters[QUERY]
    if query == nil or query == "" then
        return {}
    end
    return directNovel(query)
end

return base
