defmodule Curatorian.SocialTest do
  use Curatorian.DataCase

  alias Curatorian.Social

  describe "post_interactions" do
    alias Curatorian.Social.PostInteraction

    import Curatorian.SocialFixtures

    @invalid_attrs %{type: nil}

    test "list_post_interactions/0 returns all post_interactions" do
      post_interaction = post_interaction_fixture()
      assert Social.list_post_interactions() == [post_interaction]
    end

    test "get_post_interaction!/1 returns the post_interaction with given id" do
      post_interaction = post_interaction_fixture()
      assert Social.get_post_interaction!(post_interaction.id) == post_interaction
    end

    test "create_post_interaction/1 with valid data creates a post_interaction" do
      valid_attrs = %{type: "some type"}

      assert {:ok, %PostInteraction{} = post_interaction} = Social.create_post_interaction(valid_attrs)
      assert post_interaction.type == "some type"
    end

    test "create_post_interaction/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Social.create_post_interaction(@invalid_attrs)
    end

    test "update_post_interaction/2 with valid data updates the post_interaction" do
      post_interaction = post_interaction_fixture()
      update_attrs = %{type: "some updated type"}

      assert {:ok, %PostInteraction{} = post_interaction} = Social.update_post_interaction(post_interaction, update_attrs)
      assert post_interaction.type == "some updated type"
    end

    test "update_post_interaction/2 with invalid data returns error changeset" do
      post_interaction = post_interaction_fixture()
      assert {:error, %Ecto.Changeset{}} = Social.update_post_interaction(post_interaction, @invalid_attrs)
      assert post_interaction == Social.get_post_interaction!(post_interaction.id)
    end

    test "delete_post_interaction/1 deletes the post_interaction" do
      post_interaction = post_interaction_fixture()
      assert {:ok, %PostInteraction{}} = Social.delete_post_interaction(post_interaction)
      assert_raise Ecto.NoResultsError, fn -> Social.get_post_interaction!(post_interaction.id) end
    end

    test "change_post_interaction/1 returns a post_interaction changeset" do
      post_interaction = post_interaction_fixture()
      assert %Ecto.Changeset{} = Social.change_post_interaction(post_interaction)
    end
  end

  describe "post_interactions" do
    alias Curatorian.Social.PostInteraction

    import Curatorian.SocialFixtures

    @invalid_attrs %{type: nil, content: nil}

    test "list_post_interactions/0 returns all post_interactions" do
      post_interaction = post_interaction_fixture()
      assert Social.list_post_interactions() == [post_interaction]
    end

    test "get_post_interaction!/1 returns the post_interaction with given id" do
      post_interaction = post_interaction_fixture()
      assert Social.get_post_interaction!(post_interaction.id) == post_interaction
    end

    test "create_post_interaction/1 with valid data creates a post_interaction" do
      valid_attrs = %{type: :like, content: "some content"}

      assert {:ok, %PostInteraction{} = post_interaction} = Social.create_post_interaction(valid_attrs)
      assert post_interaction.type == :like
      assert post_interaction.content == "some content"
    end

    test "create_post_interaction/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Social.create_post_interaction(@invalid_attrs)
    end

    test "update_post_interaction/2 with valid data updates the post_interaction" do
      post_interaction = post_interaction_fixture()
      update_attrs = %{type: :retweet, content: "some updated content"}

      assert {:ok, %PostInteraction{} = post_interaction} = Social.update_post_interaction(post_interaction, update_attrs)
      assert post_interaction.type == :retweet
      assert post_interaction.content == "some updated content"
    end

    test "update_post_interaction/2 with invalid data returns error changeset" do
      post_interaction = post_interaction_fixture()
      assert {:error, %Ecto.Changeset{}} = Social.update_post_interaction(post_interaction, @invalid_attrs)
      assert post_interaction == Social.get_post_interaction!(post_interaction.id)
    end

    test "delete_post_interaction/1 deletes the post_interaction" do
      post_interaction = post_interaction_fixture()
      assert {:ok, %PostInteraction{}} = Social.delete_post_interaction(post_interaction)
      assert_raise Ecto.NoResultsError, fn -> Social.get_post_interaction!(post_interaction.id) end
    end

    test "change_post_interaction/1 returns a post_interaction changeset" do
      post_interaction = post_interaction_fixture()
      assert %Ecto.Changeset{} = Social.change_post_interaction(post_interaction)
    end
  end
end
