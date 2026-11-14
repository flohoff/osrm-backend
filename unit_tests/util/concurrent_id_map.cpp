#include "util/concurrent_id_map.hpp"
#include "guidance/turn_data_container.hpp"
#include "util/std_hash.hpp"
#include "util/typedefs.hpp"

#include <boost/test/unit_test.hpp>

#include <algorithm>
#include <cstdint>
#include <map>
#include <numeric>
#include <random>
#include <string>
#include <utility>
#include <vector>

BOOST_AUTO_TEST_SUITE(concurrent_id_map)

using namespace osrm;

using StringMap = util::ConcurrentIDMap<std::string, std::uint32_t>;

static const auto identity = [](const auto &key) { return key; };
static const auto less = [](const auto &a, const auto &b) { return a < b; };

BOOST_AUTO_TEST_CASE(renumber_sorts_by_key_and_returns_old_to_new)
{
    StringMap map;
    for (const auto *key : {"c", "a", "d", "b"})
        map.ConcurrentFindOrAdd(key);

    const auto old_to_new = map.Renumber(0, identity, less);

    BOOST_CHECK_EQUAL(map.data.at("a"), 0);
    BOOST_CHECK_EQUAL(map.data.at("b"), 1);
    BOOST_CHECK_EQUAL(map.data.at("c"), 2);
    BOOST_CHECK_EQUAL(map.data.at("d"), 3);
    // arrival order was c, a, d, b
    BOOST_CHECK((old_to_new == std::vector<std::uint32_t>{2, 0, 3, 1}));
}

BOOST_AUTO_TEST_CASE(renumber_keeps_ids_below_first_id)
{
    StringMap map;
    for (const auto *key : {"z", "y", "d", "b", "c"})
        map.ConcurrentFindOrAdd(key);

    const auto old_to_new = map.Renumber(2, identity, less);

    BOOST_CHECK_EQUAL(map.data.at("z"), 0);
    BOOST_CHECK_EQUAL(map.data.at("y"), 1);
    BOOST_CHECK_EQUAL(map.data.at("b"), 2);
    BOOST_CHECK_EQUAL(map.data.at("c"), 3);
    BOOST_CHECK_EQUAL(map.data.at("d"), 4);
    BOOST_CHECK((old_to_new == std::vector<std::uint32_t>{0, 1, 4, 2, 3}));
}

// Threads hand out IDs in arrival order, the final numbering must not depend on it.
BOOST_AUTO_TEST_CASE(renumber_is_independent_of_insertion_order)
{
    std::vector<std::string> keys;
    for (int i = 0; i < 200; ++i)
        keys.push_back("key" + std::to_string((i * 37) % 200));

    std::map<std::string, std::uint32_t> expected;
    for (unsigned seed = 0; seed < 10; ++seed)
    {
        auto shuffled = keys;
        std::shuffle(shuffled.begin(), shuffled.end(), std::mt19937(seed));
        StringMap map;
        for (const auto &key : shuffled)
            map.ConcurrentFindOrAdd(key);
        map.Renumber(0, identity, less);

        const std::map<std::string, std::uint32_t> result(map.data.begin(), map.data.end());
        if (seed == 0)
            expected = result;
        BOOST_CHECK(expected == result);
    }
}

// The lane data key holds a description ID that is renumbered first, so the key itself changes.
BOOST_AUTO_TEST_CASE(renumber_applies_the_key_map_before_ordering)
{
    using Key = std::pair<int, std::uint32_t>;
    util::ConcurrentIDMap<Key, std::uint16_t> map;
    map.ConcurrentFindOrAdd({1, 0}); // 0
    map.ConcurrentFindOrAdd({1, 1}); // 1
    map.ConcurrentFindOrAdd({0, 2}); // 2

    // description IDs 0, 1, 2 become 2, 1, 0
    const std::vector<std::uint32_t> description_remap = {2, 1, 0};
    const auto old_to_new = map.Renumber(
        0,
        [&](Key key)
        {
            key.second = description_remap[key.second];
            return key;
        },
        less);

    BOOST_CHECK_EQUAL((map.data.at({0, 0})), 0);
    BOOST_CHECK_EQUAL((map.data.at({1, 1})), 1);
    BOOST_CHECK_EQUAL((map.data.at({1, 2})), 2);
    BOOST_CHECK((old_to_new == std::vector<std::uint16_t>{2, 1, 0}));
}

// Lane and entry class IDs stored per turn must follow the renumbering, invalid IDs stay.
BOOST_AUTO_TEST_CASE(turn_data_remap_follows_renumbering)
{
    guidance::TurnDataContainer container;
    const std::vector<std::pair<LaneDataID, EntryClassID>> ids = {
        {0, 2}, {1, 0}, {2, 1}, {INVALID_LANE_DATAID, 5}};
    for (const auto &[lane_data_id, entry_class_id] : ids)
    {
        guidance::TurnData data{};
        data.lane_data_id = lane_data_id;
        data.entry_class_id = entry_class_id;
        container.push_back(data);
    }

    container.remapIDs({2, 0, 1}, {1, 2, 0});

    BOOST_CHECK_EQUAL(container.GetLaneDataID(0), 2);
    BOOST_CHECK_EQUAL(container.GetLaneDataID(1), 0);
    BOOST_CHECK_EQUAL(container.GetLaneDataID(2), 1);
    BOOST_CHECK_EQUAL(container.GetLaneDataID(3), INVALID_LANE_DATAID);
    BOOST_CHECK(!container.HasLaneData(3));
    BOOST_CHECK_EQUAL(container.GetEntryClassID(0), 0);
    BOOST_CHECK_EQUAL(container.GetEntryClassID(1), 1);
    BOOST_CHECK_EQUAL(container.GetEntryClassID(2), 2);
    // outside the remap table, left alone
    BOOST_CHECK_EQUAL(container.GetEntryClassID(3), 5);
}

BOOST_AUTO_TEST_SUITE_END()
