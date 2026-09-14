-- {"id":1308639971,"ver":"1.0.4","libVer":"1.0.0","author":"Jobobby04 / fixed","dep":["ReadWN>=1.0.11"]}
-- FanMTL fix:
-- - Current site is fanmtl.com (not fansmtl.com).
-- - ReadWN's normal search calls FanMTL's obsolete /e/search endpoint.
-- - FanMTL search is therefore replaced with a direct title -> novel slug lookup.
--
-- IMPORTANT: ext.search is deliberately a plain function(data), not
-- function(self, data). ReadWN wraps its inherited methods, but a function
-- assigned after the factory is called directly by Shosetsu.

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
    s = tostring(s or "")
    s = s:lower()
    s = s:gsub("&", " and ")
    s = s:gsub("[^%w%s%-]", "")
    s = s:gsub("%s+", "-")
    s = s:gsub("%-+", "-")
    s = s:gsub("^%-", ""):gsub("%-$", "")
    return s
end

-- Replace ReadWN's broken POST search with a direct FanMTL URL.
-- `data` is the search filter table supplied by Shosetsu.
ext.search = function(data)
    local query = data[QUERY]
    local page = data[PAGE] or 1

    if query == nil or query == "" or page ~= 1 then
        return {}
    end

    local slug = slugify(query)
    if slug == "" then
        return {}
    end

    return {
        Novel {
            title = query,
            link = "/novel/" .. slug .. ".html"
        }
    }
end

return ext
