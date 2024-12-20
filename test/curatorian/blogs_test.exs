defmodule Curatorian.BlogsTest do
  use Curatorian.DataCase

  alias Curatorian.Blogs

  describe "blogs" do
    alias Curatorian.Blogs.Blog

    import Curatorian.BlogsFixtures

    @invalid_attrs %{status: nil, title: nil, slug: nil, content: nil, summary: nil, image_url: nil}

    test "list_blogs/0 returns all blogs" do
      blog = blog_fixture()
      assert Blogs.list_blogs() == [blog]
    end

    test "get_blog!/1 returns the blog with given id" do
      blog = blog_fixture()
      assert Blogs.get_blog!(blog.id) == blog
    end

    test "create_blog/1 with valid data creates a blog" do
      valid_attrs = %{status: "some status", title: "some title", slug: "some slug", content: "some content", summary: "some summary", image_url: "some image_url"}

      assert {:ok, %Blog{} = blog} = Blogs.create_blog(valid_attrs)
      assert blog.status == "some status"
      assert blog.title == "some title"
      assert blog.slug == "some slug"
      assert blog.content == "some content"
      assert blog.summary == "some summary"
      assert blog.image_url == "some image_url"
    end

    test "create_blog/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Blogs.create_blog(@invalid_attrs)
    end

    test "update_blog/2 with valid data updates the blog" do
      blog = blog_fixture()
      update_attrs = %{status: "some updated status", title: "some updated title", slug: "some updated slug", content: "some updated content", summary: "some updated summary", image_url: "some updated image_url"}

      assert {:ok, %Blog{} = blog} = Blogs.update_blog(blog, update_attrs)
      assert blog.status == "some updated status"
      assert blog.title == "some updated title"
      assert blog.slug == "some updated slug"
      assert blog.content == "some updated content"
      assert blog.summary == "some updated summary"
      assert blog.image_url == "some updated image_url"
    end

    test "update_blog/2 with invalid data returns error changeset" do
      blog = blog_fixture()
      assert {:error, %Ecto.Changeset{}} = Blogs.update_blog(blog, @invalid_attrs)
      assert blog == Blogs.get_blog!(blog.id)
    end

    test "delete_blog/1 deletes the blog" do
      blog = blog_fixture()
      assert {:ok, %Blog{}} = Blogs.delete_blog(blog)
      assert_raise Ecto.NoResultsError, fn -> Blogs.get_blog!(blog.id) end
    end

    test "change_blog/1 returns a blog changeset" do
      blog = blog_fixture()
      assert %Ecto.Changeset{} = Blogs.change_blog(blog)
    end
  end
end
