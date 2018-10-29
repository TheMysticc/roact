return function()
	local createElement = require(script.Parent.createElement)
	local createReconciler = require(script.Parent.createReconciler)
	local getDefaultPropertyValue = require(script.Parent.getDefaultPropertyValue)
	local Portal = require(script.Parent.Portal)

	local RobloxRenderer = require(script.Parent.RobloxRenderer)

	local reconciler = createReconciler(RobloxRenderer)

	describe("mountHostNode", function()
		it("should create instances with correct props", function()
			local parent = Instance.new("Folder")
			local value = "Hello!"
			local key = "Some Key"

			local element = createElement("StringValue", {
				Value = value,
			})

			local node = reconciler.createVirtualNode(element, parent, key)

			RobloxRenderer.mountHostNode(reconciler, node)

			expect(#parent:GetChildren()).to.equal(1)

			local root = parent:GetChildren()[1]

			expect(root.ClassName).to.equal("StringValue")
			expect(root.Value).to.equal(value)
			expect(root.Name).to.equal(key)
		end)

		it("should create children with correct names and props", function()
			local parent = Instance.new("Folder")
			local rootValue = "Hey there!"
			local childValue = 173
			local key = "Some Key"

			local element = createElement("StringValue", {
				Value = rootValue,
			}, {
				ChildA = createElement("IntValue", {
					Value = childValue,
				}),

				ChildB = createElement("Folder"),
			})

			local node = reconciler.createVirtualNode(element, parent, key)

			RobloxRenderer.mountHostNode(reconciler, node)

			expect(#parent:GetChildren()).to.equal(1)

			local root = parent:GetChildren()[1]

			expect(root.ClassName).to.equal("StringValue")
			expect(root.Value).to.equal(rootValue)
			expect(root.Name).to.equal(key)

			expect(#root:GetChildren()).to.equal(2)

			local childA = root.ChildA
			local childB = root.ChildB

			expect(childA).to.be.ok()
			expect(childB).to.be.ok()

			expect(childA.ClassName).to.equal("IntValue")
			expect(childA.Value).to.equal(childValue)

			expect(childB.ClassName).to.equal("Folder")
		end)
	end)

	describe("updateHostNode", function()
		it("should update node props and children", function()
			local parent = Instance.new("Folder")
			local key = "updateHostNodeTest"
			local firstValue = "foo"
			local newValue = "bar"

			local _, defaultStringValue = getDefaultPropertyValue("StringValue", "Value")

			local element = createElement("StringValue", {
				Value = firstValue
			}, {
				ChildA = createElement("IntValue", {
					Value = 1
				}),
				ChildB = createElement("BoolValue", {
					Value = true,
				}),
				ChildC = createElement("StringValue", {
					Value = "test",
				}),
				ChildD = createElement("StringValue", {
					Value = "test",
				})
			})

			local node = reconciler.createVirtualNode(element, parent, key)
			RobloxRenderer.mountHostNode(reconciler, node)

			-- Not testing mountHostNode's work here, only testing that the
			-- node is properly updated.

			local newElement = createElement("StringValue", {
				Value = newValue,
			}, {
				-- ChildA changes element type.
				ChildA = createElement("StringValue", {
					Value = "test"
				}),
				-- ChildB changes child properties.
				ChildB = createElement("BoolValue", {
					Value = false,
				}),
				-- ChildC should reset its Value property back to the default.
				ChildC = createElement("StringValue", {}),
				-- ChildD is deleted.
				-- ChildE is added.
				ChildE = createElement("Folder", {}),
			})

			RobloxRenderer.updateHostNode(reconciler, node, newElement)

			local root = parent[key]
			expect(root.ClassName).to.equal("StringValue")
			expect(root.Value).to.equal(newValue)
			expect(#root:GetChildren()).to.equal(4)

			local childA = root.ChildA
			expect(childA.ClassName).to.equal("StringValue")
			expect(childA.Value).to.equal("test")

			local childB = root.ChildB
			expect(childB.ClassName).to.equal("BoolValue")
			expect(childB.Value).to.equal(false)

			local childC = root.ChildC
			expect(childC.ClassName).to.equal("StringValue")
			expect(childC.Value).to.equal(defaultStringValue)

			local childE = root.ChildE
			expect(childE.ClassName).to.equal("Folder")
		end)
	end)

	describe("unmountHostNode", function()
		it("should delete instances from the inside-out", function()
			local parent = Instance.new("Folder")
			local key = "Root"
			local element = createElement("Folder", nil, {
				Child = createElement("Folder", nil, {
					Grandchild = createElement("Folder"),
				}),
			})

			local node = reconciler.mountVirtualNode(element, parent, key)

			expect(#parent:GetChildren()).to.equal(1)

			local root = parent:GetChildren()[1]
			expect(#root:GetChildren()).to.equal(1)

			local child = root:GetChildren()[1]
			expect(#child:GetChildren()).to.equal(1)

			local grandchild = child:GetChildren()[1]

			RobloxRenderer.unmountHostNode(reconciler, node)

			expect(grandchild.Parent).to.equal(nil)
			expect(child.Parent).to.equal(nil)
			expect(root.Parent).to.equal(nil)
		end)
	end)

	describe("Portals", function()
		it("should place all children as children of the target Roblox instance", function()
			local target = Instance.new("Folder")

			local function FunctionComponent(props)
				return createElement("IntValue", {
					Value = props.value,
				})
			end

			local element = createElement(Portal, {
				target = target,
			}, {
				folderOne = createElement("Folder"),
				folderTwo = createElement("Folder"),
				intValueOne = createElement(FunctionComponent, {
					value = 42,
				}),
			})
			local hostParent = nil
			local key = "Some Key"
			local node = reconciler.mountVirtualNode(element, hostParent, key)

			for _, value in ipairs(target:GetChildren()) do
				print("child:", value.Name)
			end

			expect(#target:GetChildren()).to.equal(3)

			expect(target:FindFirstChild("folderOne")).to.be.ok()
			expect(target:FindFirstChild("folderTwo")).to.be.ok()
			expect(target:FindFirstChild("intValueOne")).to.be.ok()
			expect(target:FindFirstChild("intValueOne").Value).to.equal(42)

			reconciler.unmountVirtualNode(node)

			expect(#target:GetChildren()).to.equal(0)
		end)
	end)
end