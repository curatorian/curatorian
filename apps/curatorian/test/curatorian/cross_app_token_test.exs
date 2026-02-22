defmodule Curatorian.CrossAppTokenTest do
  use ExUnit.Case, async: true

  alias Curatorian.CrossAppToken

  # Mimics the map returned by Voile.Schema.Accounts.get_user_session_auth/1
  defp mock_auth_info(overrides \\ %{}) do
    Map.merge(
      %{
        user_id: Ecto.UUID.generate(),
        node_id: 42,
        node_name: "SD Negeri 1 Bandung",
        node_abbr: "SDN1BDG",
        roles: [%{name: "admin"}, %{name: "staff"}]
      },
      overrides
    )
  end

  describe "sign/1" do
    test "returns a binary token" do
      token = CrossAppToken.sign(mock_auth_info())
      assert is_binary(token)
      assert String.length(token) > 20
    end

    test "converts user_id to string" do
      uuid = Ecto.UUID.generate()
      token = CrossAppToken.sign(mock_auth_info(%{user_id: uuid}))
      {:ok, claims} = CrossAppToken.verify(token)
      assert claims.user_id == uuid
    end
  end

  describe "verify/1" do
    test "round-trips a signed token with all payload fields" do
      auth_info = mock_auth_info()
      token = CrossAppToken.sign(auth_info)

      assert {:ok, claims} = CrossAppToken.verify(token)
      assert claims.user_id == auth_info.user_id
      assert claims.node_id == auth_info.node_id
      assert claims.node_name == auth_info.node_name
      assert claims.node_abbr == auth_info.node_abbr
      assert "admin" in claims.roles
      assert "staff" in claims.roles
    end

    test "roles are encoded as name strings, not structs" do
      token = CrossAppToken.sign(mock_auth_info())
      {:ok, claims} = CrossAppToken.verify(token)

      assert Enum.all?(claims.roles, &is_binary/1)
    end

    test "returns error for tampered token" do
      assert {:error, :invalid} = CrossAppToken.verify("not.a.real.token")
    end

    test "handles user with no roles" do
      auth_info = mock_auth_info(%{roles: []})
      token = CrossAppToken.sign(auth_info)
      {:ok, claims} = CrossAppToken.verify(token)
      assert claims.roles == []
    end

    test "handles empty node_name gracefully" do
      auth_info = mock_auth_info(%{node_name: "", node_abbr: ""})
      token = CrossAppToken.sign(auth_info)
      {:ok, claims} = CrossAppToken.verify(token)
      assert claims.node_name == ""
      assert claims.node_abbr == ""
    end

    test "handles nil node_id" do
      auth_info = mock_auth_info(%{node_id: nil})
      token = CrossAppToken.sign(auth_info)
      {:ok, claims} = CrossAppToken.verify(token)
      assert claims.node_id == nil
    end
  end

  describe "salt/0" do
    test "returns the configured salt" do
      assert CrossAppToken.salt() == "cross_app_user_auth"
    end
  end

  describe "max_age/0" do
    test "returns the configured max age in seconds" do
      assert CrossAppToken.max_age() == 86_400
    end
  end
end
