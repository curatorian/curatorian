defmodule Curatorian.PersonalLibrary do
  @moduledoc "Shared personal library borrow request logic backed by the Atrium schema."

  import Ecto.Query

  alias Curatorian.Repo
  alias Curatorian.PersonalLibrary.BorrowRequest
  alias Curatorian.Public.UserProfile

  def get_owner_user_id_for_node(node_id) when is_integer(node_id) do
    UserProfile
    |> where([up], up.voile_node_id == ^node_id and is_nil(up.deleted_at))
    |> order_by([up], desc: up.is_public)
    |> limit(1)
    |> select([up], up.voile_user_id)
    |> Repo.one()
  end

  def create_borrow_request(attrs) do
    %BorrowRequest{}
    |> BorrowRequest.changeset(attrs)
    |> Repo.insert()
  end

  def get_borrow_request!(id), do: Repo.get!(BorrowRequest, id)
  def get_borrow_request(id), do: Repo.get(BorrowRequest, id)

  def list_borrow_requests_for_lender(lender_id, opts \\ []) do
    status = Keyword.get(opts, :status)

    query =
      from(r in BorrowRequest,
        where: r.lender_user_id == ^lender_id,
        order_by: [desc: r.inserted_at]
      )

    query = if status, do: where(query, [r], r.status == ^status), else: query

    Repo.all(query)
  end

  def list_borrow_requests_for_borrower(borrower_id, opts \\ []) do
    status = Keyword.get(opts, :status)

    query =
      from(r in BorrowRequest,
        where: r.borrower_user_id == ^borrower_id,
        order_by: [desc: r.inserted_at]
      )

    query = if status, do: where(query, [r], r.status == ^status), else: query

    Repo.all(query)
  end

  def change_borrow_request_status(%BorrowRequest{} = request, status)
      when status in ["pending", "approved", "declined", "canceled"] do
    request
    |> BorrowRequest.changeset(%{status: status})
    |> Repo.update()
  end
end
