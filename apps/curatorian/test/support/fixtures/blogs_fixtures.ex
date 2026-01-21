defmodule Curatorian.BlogsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Curatorian.Blogs` context.
  """

  @doc """
  Generate a unique blog slug.
  """
  def unique_blog_slug, do: "some slug#{System.unique_integer([:positive])}"

  @doc """
  Generate a blog.
  """
  def blog_fixture(attrs \\ %{}) do
    {:ok, blog} =
      attrs
      |> Enum.into(%{
        content: "some content",
        image_url: "some image_url",
        slug: unique_blog_slug(),
        status: "some status",
        summary: "some summary",
        title: "some title"
      })
      |> Curatorian.Blogs.create_blog()

    blog
  end
end
