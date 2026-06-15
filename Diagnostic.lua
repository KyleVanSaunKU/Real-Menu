local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- We use a raycast or target the specific book you are looking at to be safe, 
-- but just grabbing any book near you works for testing.
for _, book in ipairs(workspace:GetDescendants()) do
    if book.Name == "Book" and (book.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 10 then
        ReplicatedStorage.BookNetworkEvent:FireServer(book, "pickup")
        print("Fired remote for nearby book!")
        break
    end
end
