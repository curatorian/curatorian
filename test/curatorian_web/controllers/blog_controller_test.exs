defmodule CuratorianWeb.BlogControllerTest do
  use CuratorianWeb.ConnCase

  import Curatorian.BlogsFixtures

  @create_attrs %{status: "some status", title: "some title", slug: "some slug", content: "some content", summary: "some summary", image_url: "some image_url"}
  @update_attrs %{status: "some updated status", title: "some updated title", slug: "some updated slug", content: "some updated content", summary: "some updated summary", image_url: "some updated image_url"}
  @invalid_attrs %{status: nil, title: nil, slug: nil, content: nil, summary: nil, image_url: nil}

  describe "index" do
    test "lists all blogs", %{conn: conn} do
      conn = get(conn, ~p"/blogs")
      assert html_response(conn, 200) =~ "Listing Blogs"
    end
  end

  describe "new blog" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/blogs/new")
      assert html_response(conn, 200) =~ "New Blog"
    end
  end

  describe "create blog" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/blogs", blog: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/blogs/#{id}"

      conn = get(conn, ~p"/blogs/#{id}")
      assert html_response(conn, 200) =~ "Blog #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/blogs", blog: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Blog"
    end
  end

  describe "edit blog" do
    setup [:create_blog]

    test "renders form for editing chosen blog", %{conn: conn, blog: blog} do
      conn = get(conn, ~p"/blogs/#{blog}/edit")
      assert html_response(conn, 200) =~ "Edit Blog"
    end
  end

  describe "update blog" do
    setup [:create_blog]

    test "redirects when data is valid", %{conn: conn, blog: blog} do
      conn = put(conn, ~p"/blogs/#{blog}", blog: @update_attrs)
      assert redirected_to(conn) == ~p"/blogs/#{blog}"

      conn = get(conn, ~p"/blogs/#{blog}")
      assert html_response(conn, 200) =~ "some updated status"
    end

    test "renders errors when data is invalid", %{conn: conn, blog: blog} do
      conn = put(conn, ~p"/blogs/#{blog}", blog: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Blog"
    end
  end

  describe "delete blog" do
    setup [:create_blog]

    test "deletes chosen blog", %{conn: conn, blog: blog} do
      conn = delete(conn, ~p"/blogs/#{blog}")
      assert redirected_to(conn) == ~p"/blogs"

      assert_error_sent 404, fn ->
        get(conn, ~p"/blogs/#{blog}")
      end
    end
  end

  defp create_blog(_) do
    blog = blog_fixture()
    %{blog: blog}
  end
end
