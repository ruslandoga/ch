defmodule Ch do
  @moduledoc File.read!("README.md")

  def start_link(opts \\ []) do
    DBConnection.start_link(Ch.Connection, opts)
  end

  def child_spec(opts) do
    DBConnection.child_spec(Ch.Connection, opts)
  end

  def query(conn, statement, params \\ [], opts \\ []) do
    query = Ch.Query.build(statement, opts)

    with {:ok, _query, result} <- DBConnection.prepare_execute(conn, query, params, opts) do
      {:ok, result}
    end
  end

  def query!(conn, statement, params \\ [], opts \\ []) do
    query = Ch.Query.build(statement, opts)
    {_query, result} = DBConnection.prepare_execute!(conn, query, params, opts)
    result
  end

  @doc """
  Helper function that is equivalent to

      with {:ok, data} <- query(conn, [statement | "SELECT 1 + 1 FORMAT RowBinaryWithNamesAndTypes"]) do
        rows = Ch.decode_rows(data)
        {:ok, %{num_rows: length(rows), rows: rows}}
      end

  """
  def query_rows(conn, statement, params \\ [], opts \\ []) do
    # TODO
    query =
      Ch.Query.build(
        [statement | " FORMAT RowBinaryWithNamesAndTypes"],
        opts[:command] || Ch.Query.extract_command(statement)
      )

    with {:ok, _query, result} <- DBConnection.prepare_execute(conn, query, params, opts) do
      rows = Ch.decode_rows(result)
      {:ok, %{num_rows: length(rows), rows: rows}}
    end
  end

  defdelegate encode_row(row, types), to: Ch.Protocol
  defdelegate decode_rows(data), to: Ch.Protocol
end
