local LineBuilder = require("sidebar-nvim.lib.line_builder")
local renderer = require("sidebar-nvim.renderer")
local view = require("sidebar-nvim.view")
local state = require("sidebar-nvim.state")
local async = require("sidebar-nvim.lib.async")
local TestSection = require("sidebar-nvim.builtin.test")

local api = async.api

local mock = require("luassert.mock")
local spy = require("luassert.spy")

local eq = assert.are.same

local describe = async.tests.describe
local it = async.tests.it
local it_snapshot = Helpers.it_snapshot_wrapper(it, "renderer")
local before_each = async.tests.before_each
local after_each = async.tests.after_each

describe("Renderer", function()
    before_each(function()
        table.insert(state.tabs.default, TestSection:with({ title = "t1", format = "a1: %d" }))
        table.insert(state.tabs.default, TestSection:with({ title = "t2", format = "b2: %d" }))
        table.insert(state.tabs.default, TestSection:with({ title = "t3", format = "c3: %d" }))

        view.setup()
        renderer.setup()
    end)

    after_each(function()
        state.tabs.default = {}
        renderer.hl_namespace_id = nil
        renderer.extmarks_namespace_id = nil
        renderer.keymaps_namespace_id = nil
    end)

    local function draw_all()
        for i, section in ipairs(state.tabs.default) do
            renderer.draw("default", i, section, section:draw())
        end
    end

    it("setup", function()
        assert.is.truthy(renderer.hl_namespace_id)
        assert.is.truthy(renderer.extmarks_namespace_id)
        assert.is.truthy(renderer.keymaps_namespace_id)

        eq(api.nvim_buf_is_loaded(view.View.bufnr), true)
    end)

    it("first draw: no extmarks", function()
        draw_all()

        for i, section in ipairs(state.tabs.default) do
            eq(section._internal_state.extmark_id, i)
        end
    end)

    it("second draw: with extmarks", function()
        draw_all()
        draw_all()

        for i, section in ipairs(state.tabs.default) do
            eq(section._internal_state.extmark_id, i)
        end
    end)

    it_snapshot("draw: set_lines", function()
        draw_all()
    end)
end)
